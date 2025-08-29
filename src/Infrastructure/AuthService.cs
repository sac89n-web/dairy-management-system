using Dairy.Domain;
using Dapper;
using Npgsql;
using System.Security.Cryptography;
using System.Text;

namespace Dairy.Infrastructure
{
    public interface IAuthService
    {
        Task<AuthResult> LoginAsync(string username, string password);
        Task<User?> GetUserByIdAsync(int userId);
        Task<bool> HasPermissionAsync(int userId, string permission);
        Task EnsureDefaultUsersAsync();
    }

    public class AuthService : IAuthService
    {
        private readonly SqlConnectionFactory _connectionFactory;

        public AuthService(SqlConnectionFactory connectionFactory)
        {
            _connectionFactory = connectionFactory;
        }

        public async Task<AuthResult> LoginAsync(string username, string password)
        {
            using var connection = (NpgsqlConnection)_connectionFactory.CreateConnection();
            await connection.OpenAsync();
            
            await EnsureTablesExist(connection);

            var user = await connection.QuerySingleOrDefaultAsync<User>(@"
                SELECT * FROM dairy.users 
                WHERE (username = @username OR email = @username) 
                AND is_active = true", 
                new { username });

            if (user == null)
            {
                return new AuthResult { Success = false, Message = "Invalid username or password" };
            }

            if (!VerifyPassword(password, user.PasswordHash))
            {
                return new AuthResult { Success = false, Message = "Invalid username or password" };
            }

            // Update last login
            await connection.ExecuteAsync(
                "UPDATE dairy.users SET last_login_at = NOW() WHERE id = @id", 
                new { id = user.Id });

            return new AuthResult 
            { 
                Success = true, 
                User = user,
                Message = "Login successful"
            };
        }

        public async Task<User?> GetUserByIdAsync(int userId)
        {
            using var connection = (NpgsqlConnection)_connectionFactory.CreateConnection();
            await connection.OpenAsync();

            return await connection.QuerySingleOrDefaultAsync<User>(
                "SELECT * FROM dairy.users WHERE id = @userId AND is_active = true",
                new { userId });
        }

        public async Task<bool> HasPermissionAsync(int userId, string permission)
        {
            using var connection = (NpgsqlConnection)_connectionFactory.CreateConnection();
            await connection.OpenAsync();

            var user = await GetUserByIdAsync(userId);
            if (user == null) return false;

            // Admin has all permissions
            if (user.Role == UserRole.Admin) return true;

            var hasPermission = await connection.QuerySingleOrDefaultAsync<bool>(@"
                SELECT COALESCE(rp.is_granted, false)
                FROM dairy.permissions p
                LEFT JOIN dairy.role_permissions rp ON p.id = rp.permission_id AND rp.role = @role
                WHERE p.name = @permission",
                new { role = (int)user.Role, permission });

            return hasPermission;
        }

        public async Task EnsureDefaultUsersAsync()
        {
            using var connection = (NpgsqlConnection)_connectionFactory.CreateConnection();
            await connection.OpenAsync();
            
            await EnsureTablesExist(connection);
            
            var userCount = await connection.QuerySingleOrDefaultAsync<int>("SELECT COUNT(*) FROM dairy.users");
            if (userCount == 0)
            {
                // Create default admin user
                var adminPasswordHash = HashPassword("admin123");
                await connection.ExecuteAsync(@"
                    INSERT INTO dairy.users (username, email, password_hash, full_name, mobile, role, created_by)
                    VALUES ('admin', 'admin@dairy.com', @passwordHash, 'System Administrator', '9999999999', @role, 1)",
                    new { passwordHash = adminPasswordHash, role = (int)UserRole.Admin });

                // Create default permissions
                await CreateDefaultPermissions(connection);
            }
        }

        private async Task EnsureTablesExist(NpgsqlConnection connection)
        {
            await connection.ExecuteAsync(@"
                CREATE TABLE IF NOT EXISTS dairy.users (
                    id SERIAL PRIMARY KEY,
                    username VARCHAR(50) UNIQUE NOT NULL,
                    email VARCHAR(100) UNIQUE NOT NULL,
                    password_hash VARCHAR(255) NOT NULL,
                    full_name VARCHAR(100) NOT NULL,
                    mobile VARCHAR(15),
                    role INTEGER NOT NULL,
                    is_active BOOLEAN DEFAULT true,
                    created_at TIMESTAMP DEFAULT NOW(),
                    last_login_at TIMESTAMP,
                    created_by INTEGER
                )");

            await connection.ExecuteAsync(@"
                CREATE TABLE IF NOT EXISTS dairy.permissions (
                    id SERIAL PRIMARY KEY,
                    name VARCHAR(100) UNIQUE NOT NULL,
                    description VARCHAR(255),
                    module VARCHAR(50) NOT NULL
                )");

            await connection.ExecuteAsync(@"
                CREATE TABLE IF NOT EXISTS dairy.role_permissions (
                    id SERIAL PRIMARY KEY,
                    role INTEGER NOT NULL,
                    permission_id INTEGER NOT NULL REFERENCES dairy.permissions(id),
                    is_granted BOOLEAN DEFAULT true,
                    UNIQUE(role, permission_id)
                )");
        }

        private async Task CreateDefaultPermissions(NpgsqlConnection connection)
        {
            var permissions = new[]
            {
                ("milk_collection.view", "View milk collections", "Collection"),
                ("milk_collection.add", "Add milk collections", "Collection"),
                ("milk_collection.edit", "Edit milk collections", "Collection"),
                ("milk_collection.delete", "Delete milk collections", "Collection"),
                ("sales.view", "View sales", "Sales"),
                ("sales.add", "Add sales", "Sales"),
                ("sales.edit", "Edit sales", "Sales"),
                ("sales.delete", "Delete sales", "Sales"),
                ("farmers.view", "View farmers", "Master Data"),
                ("farmers.manage", "Manage farmers", "Master Data"),
                ("rates.view", "View rate slabs", "Rates"),
                ("rates.manage", "Manage rate slabs", "Rates"),
                ("reports.view", "View reports", "Reports"),
                ("reports.export", "Export reports", "Reports"),
                ("users.view", "View users", "Administration"),
                ("users.manage", "Manage users", "Administration"),
                ("dashboard.view", "View dashboard", "Dashboard")
            };

            foreach (var (name, desc, module) in permissions)
            {
                await connection.ExecuteAsync(@"
                    INSERT INTO dairy.permissions (name, description, module) 
                    VALUES (@name, @desc, @module) 
                    ON CONFLICT (name) DO NOTHING",
                    new { name, desc, module });
            }

            // Grant permissions to roles
            var rolePermissions = new[]
            {
                (UserRole.Manager, new[] { "milk_collection.view", "milk_collection.add", "milk_collection.edit", "sales.view", "sales.add", "farmers.view", "rates.view", "reports.view", "dashboard.view" }),
                (UserRole.Operator, new[] { "milk_collection.view", "milk_collection.add", "sales.view", "sales.add", "dashboard.view" }),
                (UserRole.Finance, new[] { "sales.view", "reports.view", "reports.export", "dashboard.view" }),
                (UserRole.Auditor, new[] { "milk_collection.view", "sales.view", "farmers.view", "rates.view", "reports.view", "reports.export", "dashboard.view" })
            };

            foreach (var (role, perms) in rolePermissions)
            {
                foreach (var perm in perms)
                {
                    await connection.ExecuteAsync(@"
                        INSERT INTO dairy.role_permissions (role, permission_id, is_granted)
                        SELECT @role, id, true FROM dairy.permissions WHERE name = @perm
                        ON CONFLICT (role, permission_id) DO NOTHING",
                        new { role = (int)role, perm });
                }
            }
        }

        private string HashPassword(string password)
        {
            using var sha256 = SHA256.Create();
            var hashedBytes = sha256.ComputeHash(Encoding.UTF8.GetBytes(password + "dairy_salt"));
            return Convert.ToBase64String(hashedBytes);
        }

        private bool VerifyPassword(string password, string hash)
        {
            return HashPassword(password) == hash;
        }
    }

    public class AuthResult
    {
        public bool Success { get; set; }
        public User? User { get; set; }
        public string Message { get; set; } = "";
    }
}