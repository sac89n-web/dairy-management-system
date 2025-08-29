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
        // Use session connection string from login
        var sessionConnectionString = context?.Session.GetString("ConnectionString");
        if (!string.IsNullOrEmpty(sessionConnectionString))
        {
            connectionString = sessionConnectionString;
        }
        else
        {
            // Fallback to configuration if available
            connectionString = builder.Configuration.GetConnectionString("Postgres");
            if (string.IsNullOrEmpty(connectionString))
            {
                throw new InvalidOperationException("No database connection available. Please login first.");
            }
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
    var publicPaths = new[] { "/simple-login", "/login", "/database-login", "/health", "/api/test-db", "/swagger", "/api", "/list-tables", "/db-test", "/setup-db" };
    
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

// List all tables endpoint
app.MapGet("/list-tables", async (SqlConnectionFactory dbFactory) => {
    try {
        using var connection = (NpgsqlConnection)dbFactory.CreateConnection();
        await connection.OpenAsync();
        
        using var cmd = new NpgsqlCommand("SELECT table_name FROM information_schema.tables WHERE table_schema = 'dairy' ORDER BY table_name", connection);
        using var reader = await cmd.ExecuteReaderAsync();
        
        var tables = new List<string>();
        while (await reader.ReadAsync())
        {
            tables.Add(reader.GetString(0));
        }
        
        return Results.Json(new { 
            success = true, 
            count = tables.Count,
            tables = tables
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
        
        var setupSql = @"
SET search_path TO dairy;

CREATE TABLE IF NOT EXISTS bank (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL
);

CREATE TABLE IF NOT EXISTS expense_category (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL
);

CREATE TABLE IF NOT EXISTS item (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL
);

CREATE TABLE IF NOT EXISTS payment_customer (
    id SERIAL PRIMARY KEY,
    customer_id INTEGER REFERENCES customer(id),
    sale_id INTEGER REFERENCES sale(id),
    amount NUMERIC(12,2) NOT NULL,
    date DATE NOT NULL,
    invoice_no VARCHAR(30) UNIQUE,
    pdf_path VARCHAR(255)
);

CREATE TABLE IF NOT EXISTS audit_log (
    id SERIAL PRIMARY KEY,
    user_id INTEGER,
    action VARCHAR(100) NOT NULL,
    entity VARCHAR(50),
    entity_id INTEGER,
    timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    details TEXT
);

CREATE TABLE IF NOT EXISTS settings (
    id SERIAL PRIMARY KEY,
    system_name VARCHAR(100) NOT NULL,
    contact VARCHAR(50) NOT NULL,
    address TEXT NOT NULL
);

INSERT INTO bank (name) VALUES ('State Bank of India') ON CONFLICT DO NOTHING;
INSERT INTO expense_category (name) VALUES ('Transport') ON CONFLICT DO NOTHING;
INSERT INTO item (name) VALUES ('Milk') ON CONFLICT DO NOTHING;
INSERT INTO settings (system_name, contact, address) VALUES ('Dairy Management System', '9876543210', '123 Dairy Lane') ON CONFLICT DO NOTHING;F NOT EXISTS milk_collection (
    id SERIAL PRIMARY KEY,
    farmer_id INTEGER REFERENCES farmer(id),
    shift_id INTEGER REFERENCES shift(id),
    date DATE NOT NULL,
    qty_ltr NUMERIC(8,2) NOT NULL,
    fat_pct NUMERIC(4,2) NOT NULL,
    price_per_ltr NUMERIC(8,2) NOT NULL,
    due_amt NUMERIC(12,2) NOT NULL,
    notes TEXT,
    created_by INTEGER REFERENCES employee(id)
);

CREATE TABLE IF NOT EXISTS sale (
    id SERIAL PRIMARY KEY,
    customer_id INTEGER REFERENCES customer(id),
    shift_id INTEGER REFERENCES shift(id),
    date DATE NOT NULL,
    qty_ltr NUMERIC(8,2) NOT NULL,
    unit_price NUMERIC(8,2) NOT NULL,
    discount NUMERIC(8,2) DEFAULT 0,
    paid_amt NUMERIC(12,2) NOT NULL,
    due_amt NUMERIC(12,2) NOT NULL,
    created_by INTEGER REFERENCES employee(id)
);

CREATE TABLE IF NOT EXISTS payment_farmer (
    id SERIAL PRIMARY KEY,
    farmer_id INTEGER REFERENCES farmer(id),
    milk_collection_id INTEGER REFERENCES milk_collection(id),
    amount NUMERIC(12,2) NOT NULL,
    date DATE NOT NULL,
    invoice_no VARCHAR(30) UNIQUE,
    pdf_path VARCHAR(255)
);

INSERT INTO branch (name, address, contact) VALUES ('Main Branch', '123 Dairy Lane', '9876543210') ON CONFLICT DO NOTHING;
INSERT INTO employee (name, contact, branch_id, role) VALUES ('Admin User', '9999999999', 1, 'Admin') ON CONFLICT DO NOTHING;
INSERT INTO farmer (name, code, contact, branch_id) VALUES ('Farmer A', 'F001', '7777777777', 1) ON CONFLICT (code) DO NOTHING;
INSERT INTO customer (name, contact, branch_id) VALUES ('Customer X', '5555555555', 1) ON CONFLICT DO NOTHING;
INSERT INTO shift (name, start_time, end_time) VALUES ('Morning', '06:00', '10:00') ON CONFLICT DO NOTHING;
";
        
        using var cmd = new NpgsqlCommand(setupSql, connection);
        await cmd.ExecuteNonQueryAsync();
        
        return Results.Json(new { success = true, message = "Database setup completed" });
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