using Microsoft.AspNetCore.Mvc;

var builder = WebApplication.CreateBuilder(args);

// Minimal services
builder.Services.AddControllers();

var app = builder.Build();

// Health check
app.MapGet("/health", () => Results.Ok(new { status = "healthy", timestamp = DateTime.UtcNow }));

// Root endpoint
app.MapGet("/", () => Results.Ok(new { message = "Dairy Management System", status = "running" }));

// Test endpoint
app.MapGet("/test", () => Results.Ok(new { test = "success", environment = Environment.GetEnvironmentVariable("ASPNETCORE_ENVIRONMENT") }));

var port = Environment.GetEnvironmentVariable("PORT") ?? "8080";
Console.WriteLine($"Starting on port {port}");
app.Run($"http://0.0.0.0:{port}");