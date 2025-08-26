using Dairy.Infrastructure;
using Dairy.Application;
using Dairy.Domain;
using FluentValidation.AspNetCore;
using FluentValidation;
using Serilog;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.IdentityModel.Tokens;
using Microsoft.AspNetCore.Localization;
using Microsoft.Extensions.Options;
using System.Globalization;
using System.Text;

var builder = WebApplication.CreateBuilder(args);

// Configure QuestPDF license
QuestPDF.Settings.License = QuestPDF.Infrastructure.LicenseType.Community;

// Serilog (simplified for production)
builder.Host.UseSerilog((ctx, lc) => lc
    .WriteTo.Console()
    .MinimumLevel.Information());

// Configuration
var supportedCultures = builder.Configuration.GetSection("SupportedCultures").Get<string[]>();

// Localization
builder.Services.AddLocalization(options => options.ResourcesPath = "Resources");
builder.Services.AddSingleton<Microsoft.Extensions.Localization.IStringLocalizer>(sp => 
    sp.GetRequiredService<Microsoft.Extensions.Localization.IStringLocalizerFactory>()
      .Create("Strings", System.Reflection.Assembly.GetExecutingAssembly().GetName().Name ?? ""));
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

// FluentValidation
builder.Services.AddFluentValidationAutoValidation()
    .AddFluentValidationClientsideAdapters();
builder.Services.AddValidatorsFromAssemblyContaining<ApplicationMarker>();
FluentValidation.ValidatorOptions.Global.LanguageManager.Enabled = true;

// HTTP Context Accessor
builder.Services.AddHttpContextAccessor();

// Database Services (optional - only if classes exist)
try {
    builder.Services.AddScoped<Dairy.Web.Services.DynamicConnectionFactory>();
    builder.Services.AddSingleton<Dairy.Web.Services.DatabaseSettingsService>();
} catch {
    // Services don't exist, skip
}

// Dapper/Npgsql (fallback)
builder.Services.AddSingleton<SqlConnectionFactory>(sp =>
{
    var connectionString = builder.Configuration.GetConnectionString("DefaultConnection") ?? 
                          Environment.GetEnvironmentVariable("DATABASE_URL");
    
    // Convert Railway DATABASE_URL format if needed
    if (!string.IsNullOrEmpty(connectionString) && connectionString.StartsWith("postgresql://"))
    {
        var uri = new Uri(connectionString);
        connectionString = $"Host={uri.Host};Port={uri.Port};Database={uri.AbsolutePath.Trim('/')};Username={uri.UserInfo.Split(':')[0]};Password={uri.UserInfo.Split(':')[1]};SearchPath=dairy;SSL Mode=Require;Trust Server Certificate=true";
    }
    
    connectionString ??= "Host=localhost;Database=postgres;Username=admin;Password=admin123;SearchPath=dairy";
    return new SqlConnectionFactory(connectionString);
});

// Application/Domain/Infrastructure DI
builder.Services.AddScoped<ICollectionRepository, CollectionRepository>();
builder.Services.AddScoped<ISaleRepository, SaleRepository>();
builder.Services.AddScoped<IPaymentCustomerRepository, PaymentCustomerRepository>();
builder.Services.AddScoped<IPaymentFarmerRepository, PaymentFarmerRepository>();
builder.Services.AddScoped<IAuditLogRepository, AuditLogRepository>();
builder.Services.AddSingleton<IWeighingMachineService, WeighingMachineService>();

// Report Services
builder.Services.AddScoped<Dairy.Reports.ExcelReportService>();
builder.Services.AddScoped<Dairy.Reports.PdfReportService>();
builder.Services.AddSingleton<Dairy.Application.SettingsCache>();

// Optional Services (only if classes exist)
try {
    builder.Services.AddHttpClient<Dairy.Web.Services.DigiLockerService>();
    builder.Services.AddScoped<Dairy.Web.Services.PythonDbService>();
    builder.Services.AddScoped<Dairy.Web.Services.OtpService>();
} catch {
    // Services don't exist, skip
}

// Session support
builder.Services.AddDistributedMemoryCache();
builder.Services.AddSession(options =>
{
    options.IdleTimeout = TimeSpan.FromHours(2);
    options.Cookie.HttpOnly = true;
    options.Cookie.IsEssential = true;
});

// Razor Pages, Minimal APIs
builder.Services.AddRazorPages();
builder.Services.AddControllers();
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen();

var app = builder.Build();

// Session middleware
app.UseSession();

// Authentication middleware
app.Use(async (context, next) =>
{
    var publicPaths = new[] { "/simple-login", "/login", "/database-login", "/health", "/api/test-db" };
    
    if (!publicPaths.Any(p => context.Request.Path.StartsWithSegments(p)) && 
        context.Session.GetString("UserId") == null)
    {
        context.Response.Redirect("/simple-login");
        return;
    }
    
    await next();
});

// Localization Middleware
var locOptions = app.Services.GetRequiredService<IOptions<RequestLocalizationOptions>>().Value;
app.UseRequestLocalization(locOptions);

// Error Handling, Security
app.UseSerilogRequestLogging();
app.UseHttpsRedirection();
app.UseStaticFiles();
app.UseRouting();
app.UseAuthentication();
app.UseAuthorization();

// Swagger
app.UseSwagger();
app.UseSwaggerUI();

// Endpoints
app.MapRazorPages();
app.MapControllers();

// Default route to simple login
app.MapGet("/", () => Results.Redirect("/simple-login"));

// Database test endpoint
app.MapGet("/api/test-db", async () => {
    try {
        var connectionString = Environment.GetEnvironmentVariable("DATABASE_URL") ?? "Host=localhost;Database=postgres;Username=admin;Password=admin123";
        
        if (connectionString.StartsWith("postgresql://")) {
            var uri = new Uri(connectionString);
            connectionString = $"Host={uri.Host};Port={uri.Port};Database={uri.AbsolutePath.Trim('/')};Username={uri.UserInfo.Split(':')[0]};Password={uri.UserInfo.Split(':')[1]};SSL Mode=Require;Trust Server Certificate=true";
        }
        
        using var connection = new Npgsql.NpgsqlConnection(connectionString);
        await connection.OpenAsync();
        
        var cmd = new Npgsql.NpgsqlCommand("SELECT version()", connection);
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

// Health check endpoint
app.MapGet("/health", () => Results.Ok(new { status = "healthy", timestamp = DateTime.UtcNow }));

var port = Environment.GetEnvironmentVariable("PORT") ?? "8080";
app.Logger.LogInformation("Starting Dairy Management System on port {Port}", port);
app.Run($"http://0.0.0.0:{port}");

// Marker classes for DI
namespace Dairy.Application { public class ApplicationMarker { } }
namespace Dairy.Domain { public class DomainMarker { } }
namespace Dairy.Infrastructure { public class InfrastructureMarker { } }