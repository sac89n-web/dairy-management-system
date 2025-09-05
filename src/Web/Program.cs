using Serilog;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.IdentityModel.Tokens;
using Microsoft.AspNetCore.Localization;
using Microsoft.Extensions.Options;
using System.Globalization;
using System.Text;
using Dairy.Infrastructure;
using Dairy.Application;
using Dairy.Reports;
using FluentValidation;
using FluentValidation.AspNetCore;
using Npgsql;

var builder = WebApplication.CreateBuilder(args);

// Configure QuestPDF license
QuestPDF.Settings.License = QuestPDF.Infrastructure.LicenseType.Community;

// Serilog - Environment-based configuration
builder.Host.UseSerilog((ctx, lc) => {
    var config = lc.WriteTo.Console().MinimumLevel.Information();
    
    // Only write to file in local environment
    if (ctx.HostingEnvironment.IsDevelopment())
    {
        config.WriteTo.File("logs/dairy-.txt", rollingInterval: RollingInterval.Day);
    }
});

// Configuration
var supportedCultures = builder.Configuration.GetSection("SupportedCultures").Get<string[]>();

// Localization
builder.Services.AddLocalization(options => options.ResourcesPath = "Resources");
builder.Services.Configure<RequestLocalizationOptions>(options =>
{
    var cultures = (supportedCultures != null && supportedCultures.Length > 0 ? supportedCultures : new[] { "en-IN", "hi-IN", "mr-IN" }).Select(c => new CultureInfo(c)).ToList();
    options.DefaultRequestCulture = new RequestCulture("en-IN");
    options.SupportedCultures = cultures;
    options.SupportedUICultures = cultures;
    options.RequestCultureProviders.Clear();
    options.RequestCultureProviders.Add(new CookieRequestCultureProvider());
    options.RequestCultureProviders.Add(new AcceptLanguageHeaderRequestCultureProvider());
});

// JWT Auth
builder.Services.AddAuthentication(JwtBearerDefaults.AuthenticationScheme)
    .AddJwtBearer(options =>
    {
        options.TokenValidationParameters = new TokenValidationParameters
        {
            ValidateIssuer = true,
            ValidateAudience = true,
            ValidateLifetime = true,
            ValidateIssuerSigningKey = true,
            ValidIssuer = builder.Configuration["Jwt:Issuer"],
            ValidAudience = builder.Configuration["Jwt:Audience"],
            IssuerSigningKey = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(builder.Configuration["Jwt:Key"] ?? "default-key-for-development"))
        };
    });

// HTTP Context Accessor
builder.Services.AddHttpContextAccessor();

// Database and Infrastructure Services
builder.Services.AddScoped<SqlConnectionFactory>(sp =>
{
    var httpContextAccessor = sp.GetRequiredService<IHttpContextAccessor>();
    var context = httpContextAccessor.HttpContext;
    
    var dbUrl = Environment.GetEnvironmentVariable("DATABASE_URL");
    
    string connectionString;
    if (!string.IsNullOrEmpty(dbUrl))
    {
        if (dbUrl.StartsWith("postgresql://"))
        {
            // Parse Render DATABASE_URL format: postgresql://user:password@host:port/database
            var uri = new Uri(dbUrl);
            var userInfo = uri.UserInfo.Split(':');
            var database = uri.AbsolutePath.TrimStart('/');
            connectionString = $"Host={uri.Host};Port={uri.Port};Database={database};Username={userInfo[0]};Password={userInfo[1]};SSL Mode=Require;Trust Server Certificate=true;SearchPath=dairy";
        }
        else
        {
            // Direct connection string format
            connectionString = dbUrl + (dbUrl.Contains("SearchPath") ? "" : ";SearchPath=dairy");
        }
    }
    else
    {
        // Use session connection string from login
        var sessionConnectionString = context?.Session.GetString("ConnectionString");
        if (!string.IsNullOrEmpty(sessionConnectionString))
        {
            connectionString = sessionConnectionString;
        }
        else
        {
            // Fallback to local development connection
            connectionString = "Host=localhost;Database=postgres;Username=admin;Password=admin123;SearchPath=dairy";
        }
    }
    
    return new SqlConnectionFactory(connectionString);
});

// Repository Services
builder.Services.AddScoped<CollectionRepository>();
builder.Services.AddScoped<SaleRepository>();
builder.Services.AddScoped<PaymentFarmerRepository>();
builder.Services.AddScoped<PaymentCustomerRepository>();
builder.Services.AddScoped<AuditLogRepository>();
builder.Services.AddScoped<HardwareRepository>();

// Application Services
builder.Services.AddScoped<SettingsCache>();
builder.Services.AddScoped<WeighingMachineService>();
builder.Services.AddScoped<IRateEngineService, RateEngineService>();
builder.Services.AddScoped<IDashboardService, DashboardService>();
builder.Services.AddScoped<IAuthService, AuthService>();

// Feedback Implementation Services
builder.Services.AddScoped<IPaymentCycleService, PaymentCycleService>();
builder.Services.AddScoped<IBonusService, BonusService>();
builder.Services.AddScoped<IAdvancedNotificationService, AdvancedNotificationService>();
builder.Services.AddScoped<IAdvancedAnalyticsService, AdvancedAnalyticsService>();

// HTTP Client and DigiLocker Service
builder.Services.AddHttpClient();
builder.Services.AddScoped<Dairy.Web.Services.DigiLockerService>();
builder.Services.AddScoped<Dairy.Web.Services.DatabaseSettingsService>();

// Phase 2: Hardware Services
builder.Services.AddScoped<Dairy.Infrastructure.HardwareServices.IDigitalScaleService, Dairy.Infrastructure.HardwareServices.DigitalScaleService>();
builder.Services.AddScoped<Dairy.Infrastructure.HardwareServices.IMilkAnalyzerService, Dairy.Infrastructure.HardwareServices.MilkAnalyzerService>();
builder.Services.AddScoped<Dairy.Infrastructure.HardwareServices.IThermalPrinterService, Dairy.Infrastructure.HardwareServices.ThermalPrinterService>();
builder.Services.AddScoped<Dairy.Infrastructure.HardwareServices.IRfidService, Dairy.Infrastructure.HardwareServices.RfidService>();
builder.Services.AddScoped<Dairy.Infrastructure.HardwareServices.IHardwareIntegrationService, Dairy.Infrastructure.HardwareServices.HardwareIntegrationService>();

// Phase 3: KYC, Payments & Notifications
builder.Services.AddScoped<IKycVerificationService, KycVerificationService>();
builder.Services.AddScoped<IPaymentGatewayService, PaymentGatewayService>();

// Phase 4: Advanced Analytics & Enterprise Features
builder.Services.AddScoped<IBranchManagementService, BranchManagementService>();
builder.Services.AddScoped<IMobileAppService, MobileAppService>();

// Report Services
builder.Services.AddScoped<ExcelReportService>();
builder.Services.AddScoped<PdfReportService>();

// Validation - Commented out for now to avoid DI issues
// builder.Services.AddFluentValidationAutoValidation();
// builder.Services.AddValidatorsFromAssemblyContaining<MilkCollectionValidator>();

// Session support
builder.Services.AddDistributedMemoryCache();
builder.Services.AddSession(options =>
{
    options.IdleTimeout = TimeSpan.FromHours(2);
    options.Cookie.HttpOnly = true;
    options.Cookie.IsEssential = true;
});

// Razor Pages, Controllers
builder.Services.AddRazorPages();
builder.Services.AddControllers();
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen();

var app = builder.Build();

// Session middleware
app.UseSession();

// Authentication middleware
app.UseMiddleware<Dairy.Web.Middleware.AuthorizationMiddleware>();

// Localization Middleware
var locOptions = app.Services.GetRequiredService<IOptions<RequestLocalizationOptions>>().Value;
app.UseRequestLocalization(locOptions);

// Configure pipeline
app.UseSerilogRequestLogging();
app.UseHttpsRedirection();
app.UseStaticFiles();
app.UseRouting();
app.UseAuthentication();
app.UseAuthorization();

// Swagger
if (app.Environment.IsDevelopment())
{
    app.UseSwagger();
    app.UseSwaggerUI();
}

// Endpoints
app.MapRazorPages();
app.MapControllers();

// Default route to dashboard
app.MapGet("/", () => Results.Redirect("/dashboard"));

// Map feedback features endpoints
Dairy.Web.FeedbackFeaturesEndpoints.MapFeedbackFeatures(app);

// Basic API endpoints
app.MapGet("/api/milk-collections", MilkCollectionEndpoints.List);
app.MapPost("/api/milk-collections", MilkCollectionEndpoints.Add);
app.MapPut("/api/milk-collections/{id}", MilkCollectionEndpoints.Update);
app.MapDelete("/api/milk-collections/{id}", MilkCollectionEndpoints.Delete);

app.MapGet("/api/sales", SaleEndpoints.List);
app.MapPost("/api/sales", SaleEndpoints.Add);

// Rate calculation endpoints
app.MapGet("/api/rate/calculate", RateEndpoints.CalculateRate);
app.MapGet("/api/rate/slabs", RateEndpoints.GetActiveSlabs);

// Enhanced database test endpoint
app.MapGet("/api/test-db", async (SqlConnectionFactory dbFactory) => {
    try {
        using var connection = (Npgsql.NpgsqlConnection)dbFactory.CreateConnection();
        await connection.OpenAsync();
        
        // Test basic connection
        using var versionCmd = new Npgsql.NpgsqlCommand("SELECT version()", connection);
        var version = await versionCmd.ExecuteScalarAsync();
        
        // Test dairy schema
        using var schemaCmd = new Npgsql.NpgsqlCommand("SELECT COUNT(*) FROM information_schema.schemata WHERE schema_name = 'dairy'", connection);
        var schemaExists = Convert.ToInt32(await schemaCmd.ExecuteScalarAsync()) > 0;
        
        // Test table count
        using var tableCmd = new Npgsql.NpgsqlCommand("SELECT COUNT(*) FROM information_schema.tables WHERE table_schema = 'dairy'", connection);
        var tableCount = Convert.ToInt32(await tableCmd.ExecuteScalarAsync());
        
        return Results.Json(new { 
            success = true, 
            message = "Database connection successful",
            version = version?.ToString(),
            schemaExists = schemaExists,
            tableCount = tableCount,
            connectionString = connection.ConnectionString.Contains("Password=") ? 
                connection.ConnectionString.Substring(0, connection.ConnectionString.IndexOf("Password=")) + "Password=***" :
                connection.ConnectionString
        });
    } catch (Exception ex) {
        return Results.Json(new { 
            success = false, 
            error = ex.Message,
            stackTrace = ex.StackTrace
        });
    }
});

// Enhanced health check endpoint
app.MapGet("/health", async (SqlConnectionFactory dbFactory) => {
    var health = new {
        status = "healthy",
        timestamp = DateTime.UtcNow,
        version = "1.0.0",
        environment = app.Environment.EnvironmentName,
        database = "unknown"
    };
    
    try {
        using var connection = (NpgsqlConnection)dbFactory.CreateConnection();
        await connection.OpenAsync();
        health = health with { database = "connected" };
    } catch {
        health = health with { database = "disconnected", status = "degraded" };
    }
    
    return Results.Ok(health);
});

// Database test endpoint
app.MapGet("/db-test", async (SqlConnectionFactory dbFactory) => {
    try {
        using var connection = (NpgsqlConnection)dbFactory.CreateConnection();
        await connection.OpenAsync();
        
        using var cmd = new NpgsqlCommand("SELECT version()", connection);
        var version = await cmd.ExecuteScalarAsync();
        
        return Results.Json(new { 
            success = true, 
            message = "Connected successfully",
            version = version?.ToString()
        });
    } catch (Exception ex) {
        return Results.Json(new { success = false, error = ex.Message });
    }
});

// List all tables endpoint with detailed schema info
app.MapGet("/list-tables", async (SqlConnectionFactory dbFactory) => {
    try {
        using var connection = (NpgsqlConnection)dbFactory.CreateConnection();
        await connection.OpenAsync();
        
        using var cmd = new NpgsqlCommand(@"
            SELECT 
                t.table_name,
                COUNT(c.column_name) as column_count,
                string_agg(c.column_name, ', ' ORDER BY c.ordinal_position) as columns
            FROM information_schema.tables t
            LEFT JOIN information_schema.columns c ON t.table_name = c.table_name AND t.table_schema = c.table_schema
            WHERE t.table_schema = 'dairy'
            GROUP BY t.table_name
            ORDER BY t.table_name", connection);
        using var reader = await cmd.ExecuteReaderAsync();
        
        var tables = new List<object>();
        while (await reader.ReadAsync())
        {
            tables.Add(new {
                name = reader.GetString(0),
                columnCount = reader.GetInt32(1),
                columns = reader.IsDBNull(2) ? "" : reader.GetString(2)
            });
        }
        
        return Results.Json(new { 
            success = true, 
            count = tables.Count,
            tables = tables,
            schema = "dairy"
        });
    } catch (Exception ex) {
        return Results.Json(new { success = false, error = ex.Message });
    }
});

// Database setup endpoint
app.MapGet("/setup-db", async (SqlConnectionFactory dbFactory) => {
    try {
        using var connection = (NpgsqlConnection)dbFactory.CreateConnection();
        await connection.OpenAsync();
        
        // Read the complete schema file
        var schemaPath = Path.Combine(Directory.GetCurrentDirectory(), "complete_schema_sync.sql");
        string setupSql;
        
        if (File.Exists(schemaPath))
        {
            setupSql = await File.ReadAllTextAsync(schemaPath);
        }
        else
        {
            // Fallback minimal schema
            setupSql = @"
CREATE SCHEMA IF NOT EXISTS dairy;
SET search_path TO dairy;

CREATE TABLE IF NOT EXISTS branch (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    address TEXT,
    contact VARCHAR(15)
);

CREATE TABLE IF NOT EXISTS users (
    id SERIAL PRIMARY KEY,
    username VARCHAR(50) UNIQUE NOT NULL,
    full_name VARCHAR(100) NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    role INTEGER DEFAULT 1,
    is_active BOOLEAN DEFAULT TRUE
);

INSERT INTO branch (name, address, contact) 
SELECT 'Main Branch', '123 Dairy Lane', '9876543210'
WHERE NOT EXISTS (SELECT 1 FROM branch);

INSERT INTO users (username, full_name, password_hash, role, is_active) 
SELECT 'admin', 'System Administrator', 'admin123', 1, TRUE
WHERE NOT EXISTS (SELECT 1 FROM users WHERE username = 'admin');
";
        }
        
        using var cmd = new NpgsqlCommand(setupSql, connection);
        await cmd.ExecuteNonQueryAsync();
        
        // Verify setup
        using var verifyCmd = new NpgsqlCommand(@"
            SELECT COUNT(*) as table_count 
            FROM information_schema.tables 
            WHERE table_schema = 'dairy'", connection);
        var tableCount = await verifyCmd.ExecuteScalarAsync();
        
        return Results.Json(new { 
            success = true, 
            message = "Database setup completed successfully",
            tablesCreated = tableCount
        });
    } catch (Exception ex) {
        return Results.Json(new { success = false, error = ex.Message, stackTrace = ex.StackTrace });
    }
});



// Environment-based port binding
var port = Environment.GetEnvironmentVariable("PORT");
if (!string.IsNullOrEmpty(port))
{
    app.Urls.Add($"http://0.0.0.0:{port}");
}

app.Logger.LogInformation("Starting Dairy Management System on {Urls}", string.Join(", ", app.Urls));
app.Run();