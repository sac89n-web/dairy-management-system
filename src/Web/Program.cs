var builder = WebApplication.CreateBuilder(args);

// Add services
builder.Services.AddControllers();
builder.Services.AddRazorPages();

var app = builder.Build();

// Configure pipeline
app.UseStaticFiles();
app.UseRouting();

// Health check
app.MapGet("/health", () => Results.Ok(new { status = "healthy", timestamp = DateTime.UtcNow }));

// Root endpoint - redirect to login
app.MapGet("/", () => Results.Redirect("/login"));

// Login page
app.MapGet("/login", () => Results.Content(@"
<!DOCTYPE html>
<html>
<head>
    <title>Dairy Management System - Login</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 0; padding: 40px; background: #f5f5f5; }
        .container { max-width: 400px; margin: 0 auto; background: white; padding: 30px; border-radius: 10px; box-shadow: 0 2px 10px rgba(0,0,0,0.1); }
        h1 { color: #28a745; text-align: center; margin-bottom: 30px; }
        .form-group { margin-bottom: 20px; }
        label { display: block; margin-bottom: 5px; font-weight: bold; }
        input { width: 100%; padding: 10px; border: 1px solid #ddd; border-radius: 5px; box-sizing: border-box; }
        button { width: 100%; padding: 12px; background: #28a745; color: white; border: none; border-radius: 5px; font-size: 16px; cursor: pointer; }
        button:hover { background: #218838; }
        .success { background: #d4edda; border: 1px solid #c3e6cb; padding: 15px; border-radius: 5px; margin-bottom: 20px; }
    </style>
</head>
<body>
    <div class='container'>
        <h1>🥛 Dairy Management System</h1>
        <div class='success'>
            <h3>✅ Successfully Deployed!</h3>
            <p>Your dairy management system is now running on Render.com</p>
        </div>
        <form action='/dashboard' method='get'>
            <div class='form-group'>
                <label>Username:</label>
                <input type='text' name='username' value='admin' required>
            </div>
            <div class='form-group'>
                <label>Password:</label>
                <input type='password' name='password' value='admin123' required>
            </div>
            <button type='submit'>Login to Dashboard</button>
        </form>
        <p style='text-align: center; margin-top: 20px; color: #666;'>
            Demo credentials: admin / admin123
        </p>
    </div>
</body>
</html>
", "text/html"));

// Dashboard
app.MapGet("/dashboard", () => Results.Content(@"
<!DOCTYPE html>
<html>
<head>
    <title>Dairy Management Dashboard</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 0; padding: 20px; background: #f5f5f5; }
        .header { background: #28a745; color: white; padding: 20px; border-radius: 10px; margin-bottom: 20px; }
        .cards { display: grid; grid-template-columns: repeat(auto-fit, minmax(300px, 1fr)); gap: 20px; }
        .card { background: white; padding: 20px; border-radius: 10px; box-shadow: 0 2px 10px rgba(0,0,0,0.1); }
        .card h3 { color: #28a745; margin-top: 0; }
        .btn { display: inline-block; padding: 10px 20px; background: #007bff; color: white; text-decoration: none; border-radius: 5px; margin: 5px; }
        .btn:hover { background: #0056b3; }
        .status { background: #d4edda; border: 1px solid #c3e6cb; padding: 15px; border-radius: 5px; margin-bottom: 20px; }
    </style>
</head>
<body>
    <div class='header'>
        <h1>🥛 Dairy Management System Dashboard</h1>
        <p>Complete milk collection and sales management solution</p>
    </div>
    
    <div class='status'>
        <h3>✅ System Status: Online</h3>
        <p>Successfully deployed on Render.com | Environment: Production</p>
    </div>
    
    <div class='cards'>
        <div class='card'>
            <h3>📊 Milk Collection</h3>
            <p>Track daily milk collection from farmers</p>
            <a href='/api/collections' class='btn'>View Collections API</a>
        </div>
        
        <div class='card'>
            <h3>💰 Sales Management</h3>
            <p>Manage milk sales to customers</p>
            <a href='/api/sales' class='btn'>View Sales API</a>
        </div>
        
        <div class='card'>
            <h3>👥 Farmer Management</h3>
            <p>Manage farmer profiles and payments</p>
            <a href='/api/farmers' class='btn'>View Farmers API</a>
        </div>
        
        <div class='card'>
            <h3>🏪 Customer Management</h3>
            <p>Manage customer accounts and orders</p>
            <a href='/api/customers' class='btn'>View Customers API</a>
        </div>
        
        <div class='card'>
            <h3>📈 Reports</h3>
            <p>Generate Excel and PDF reports</p>
            <a href='/api/reports' class='btn'>View Reports API</a>
        </div>
        
        <div class='card'>
            <h3>⚙️ System Health</h3>
            <p>Monitor system status and performance</p>
            <a href='/health' class='btn'>Health Check</a>
        </div>
    </div>
</body>
</html>
", "text/html"));

// API endpoints
app.MapGet("/api/collections", () => Results.Ok(new { message = "Milk Collections API", status = "Ready for database integration" }));
app.MapGet("/api/sales", () => Results.Ok(new { message = "Sales API", status = "Ready for database integration" }));
app.MapGet("/api/farmers", () => Results.Ok(new { message = "Farmers API", status = "Ready for database integration" }));
app.MapGet("/api/customers", () => Results.Ok(new { message = "Customers API", status = "Ready for database integration" }));
app.MapGet("/api/reports", () => Results.Ok(new { message = "Reports API", status = "Ready for database integration" }));

var port = Environment.GetEnvironmentVariable("PORT") ?? "8080";
Console.WriteLine($"🚀 Dairy Management System starting on port {port}");
app.Run($"http://0.0.0.0:{port}");