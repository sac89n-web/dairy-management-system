namespace Dairy.Domain
{
    public class User
    {
        public int Id { get; set; }
        public string Username { get; set; } = "";
        public string Email { get; set; } = "";
        public string PasswordHash { get; set; } = "";
        public string FullName { get; set; } = "";
        public string Mobile { get; set; } = "";
        public UserRole Role { get; set; }
        public bool IsActive { get; set; } = true;
        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
        public DateTime? LastLoginAt { get; set; }
        public int? CreatedBy { get; set; }
    }

    public enum UserRole
    {
        Admin = 1,
        Manager = 2,
        Operator = 3,
        Finance = 4,
        Auditor = 5
    }

    public class Permission
    {
        public int Id { get; set; }
        public string Name { get; set; } = "";
        public string Description { get; set; } = "";
        public string Module { get; set; } = "";
    }

    public class RolePermission
    {
        public int Id { get; set; }
        public UserRole Role { get; set; }
        public int PermissionId { get; set; }
        public bool IsGranted { get; set; } = true;
    }
}