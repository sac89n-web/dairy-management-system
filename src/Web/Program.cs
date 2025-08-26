var builder = WebApplication.CreateBuilder(args);

builder.Services.AddControllers();

var app = builder.Build();

// Health check
app.MapGet("/health", () => Results.Ok(new { status = "healthy", timestamp = DateTime.UtcNow }));

// Root endpoint
app.MapGet("/", () => Results.Ok(new { 
    message = "Dairy Management System", 
    status = "running", 
    version = "1.0.0",
    endpoints = new[] { "/health", "/login", "/dashboard", "/api/collections", "/api/sales" }
}));

// Login endpoint
app.MapGet("/login", () => Results.Ok(new { 
    page = "login", 
    message = "Dairy Management System Login",
    demo_credentials = new { username = "admin", password = "admin123" }
}));

// Dashboard endpoint
app.MapGet("/dashboard", () => Results.Ok(new { 
    page = "dashboard", 
    message = "Dairy Management Dashboard",
    modules = new[] { "Collections", "Sales", "Farmers", "Customers", "Reports" },
    status = "online"
}));

// API endpoints
app.MapGet("/api/collections", () => Results.Ok(new { 
    module = "Milk Collections", 
    status = "Ready",
    features = new[] { "Daily collection tracking", "Farmer payments", "Quality testing" }
}));

app.MapGet("/api/sales", () => Results.Ok(new { 
    module = "Sales Management", 
    status = "Ready",
    features = new[] { "Customer orders", "Inventory tracking", "Invoice generation" }
}));

app.MapGet("/api/farmers", () => Results.Ok(new { 
    module = "Farmer Management", 
    status = "Ready",
    features = new[] { "Profile management", "Payment history", "Milk quality records" }
}));

app.MapGet("/api/customers", () => Results.Ok(new { 
    module = "Customer Management", 
    status = "Ready",
    features = new[] { "Account management", "Order history", "Billing" }
}));

app.MapGet("/api/reports", () => Results.Ok(new { 
    module = "Reports", 
    status = "Ready",
    formats = new[] { "Excel", "PDF", "JSON" },
    types = new[] { "Daily collections", "Monthly sales", "Farmer payments" }
}));

var port = Environment.GetEnvironmentVariable("PORT") ?? "8080";
Console.WriteLine($"Dairy Management System starting on port {port}");
app.Run($"http://0.0.0.0:{port}");