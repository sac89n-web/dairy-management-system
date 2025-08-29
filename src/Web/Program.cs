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
builder.Services.AddSingleton<SqlConnectionFactory>(sp =>
{
    var dbUrl = Environment.GetEnvironmentVariable("DATABASE_URL");
    
    string connectionString;
    if (!string.IsNullOrEmpty(dbUrl))
    {
        if (dbUrl.StartsWith("postgresql://"))
        {
            // Parse Render DATABASE_URL format
            var uri = new Uri(dbUrl);
            var userInfo = uri.UserInfo.Split(':');
            connectionString = $"Host={uri.Host};Port={uri.Port};Database={uri.AbsolutePath.Trim('/')};Username={userInfo[0]};Password={userInfo[1]};SSL Mode=Require;Trust Server Certificate=true;SearchPath=dairy";
        }
        else
        {
            // Direct connection string format
            connectionString = dbUrl + ";SearchPath=dairy";
        }
    }
    else
    {
        // Use local configuration
        connectionString = builder.Configuration.GetConnectionString("Postgres") ?? 
                          "Host=localhost;Database=postgres;Username=admin;Password=admin123;SearchPath=dairy";
    }
    
    return new SqlConnectionFactory(connectionString);
});

// Repository Services
builder.Services.AddScoped<CollectionRepository>();
builder.Services.AddScoped<SaleRepository>();
builder.Services.AddScoped<PaymentFarmerRepository>();
builder.Services.AddScoped<PaymentCustomerRepository>();
builder.Services.AddScoped<AuditLogRepository>();

// Application Services
builder.Services.AddScoped<SettingsCache>();
builder.Services.AddScoped<WeighingMachineService>();

// HTTP Client and DigiLocker Service
builder.Services.AddHttpClient();
builder.Services.AddScoped<Dairy.Web.Services.DigiLockerService>();

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
app.Use(async (context, next) =>
{
    var publicPaths = new[] { "/simple-login", "/login", "/database-login", "/health", "/api/test-db", "/swagger", "/api" };
    
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

// Basic API endpoints
app.MapGet("/api/milk-collections", MilkCollectionEndpoints.List);
app.MapPost("/api/milk-collections", MilkCollectionEndpoints.Add);
app.MapPut("/api/milk-collections/{id}", MilkCollectionEndpoints.Update);
app.MapDelete("/api/milk-collections/{id}", MilkCollectionEndpoints.Delete);

app.MapGet("/api/sales", SaleEndpoints.List);
app.MapPost("/api/sales", SaleEndpoints.Add);

// Database test endpoint
app.MapGet("/api/test-db", async (SqlConnectionFactory dbFactory) => {
    try {
        using var connection = (Npgsql.NpgsqlConnection)dbFactory.CreateConnection();
        await connection.OpenAsync();
        
        using var cmd = new Npgsql.NpgsqlCommand("SELECT version()", connection);
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



// Environment-based port binding
var port = Environment.GetEnvironmentVariable("PORT");
if (!string.IsNullOrEmpty(port))
{
    app.Urls.Add($"http://0.0.0.0:{port}");
}

app.Logger.LogInformation("Starting Dairy Management System on {Urls}", string.Join(", ", app.Urls));
app.Run();