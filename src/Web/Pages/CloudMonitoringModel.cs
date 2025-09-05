using Microsoft.AspNetCore.Mvc.RazorPages;

namespace Dairy.Web.Pages;

public class CloudMonitoringModel : PageModel
{
    public string SystemStatus { get; set; } = "Online";
    public string Uptime { get; set; } = "99.9%";
    public int ResponseTime { get; set; } = 145;
    public int MemoryUsage { get; set; } = 68;
    public decimal MemoryUsed { get; set; } = 6.8m;
    public decimal TotalMemory { get; set; } = 10.0m;
    public int CpuUsage { get; set; } = 35;

    public decimal DatabaseSize { get; set; } = 2.5m;
    public decimal LogsSize { get; set; } = 0.8m;
    public decimal BackupsSize { get; set; } = 1.2m;
    public decimal TotalStorage { get; set; } = 20.0m;

    public List<DatabaseMetric> DatabaseMetrics { get; set; } = new();
    public List<ApiEndpoint> ApiEndpoints { get; set; } = new();
    public List<SystemLog> SystemLogs { get; set; } = new();
    public List<SystemAlert> Alerts { get; set; } = new();
    public List<ResponseTimePoint> ResponseTimeHistory { get; set; } = new();
    public List<ResourcePoint> ResourceHistory { get; set; } = new();

    public async Task OnGetAsync()
    {
        // Sample database metrics
        DatabaseMetrics = new List<DatabaseMetric>
        {
            new() { MetricName = "Connection Pool", CurrentValue = 15, Threshold = 50, Unit = "connections", Status = "Good", LastUpdated = DateTime.Now },
            new() { MetricName = "Query Response Time", CurrentValue = 25, Threshold = 100, Unit = "ms", Status = "Good", LastUpdated = DateTime.Now },
            new() { MetricName = "Active Transactions", CurrentValue = 8, Threshold = 20, Unit = "count", Status = "Good", LastUpdated = DateTime.Now },
            new() { MetricName = "Lock Waits", CurrentValue = 2, Threshold = 5, Unit = "count", Status = "Warning", LastUpdated = DateTime.Now },
            new() { MetricName = "Deadlocks", CurrentValue = 0, Threshold = 1, Unit = "count", Status = "Good", LastUpdated = DateTime.Now }
        };

        // Sample API endpoints
        ApiEndpoints = new List<ApiEndpoint>
        {
            new() { Path = "/api/milk-collections", Method = "GET", RequestsPerHour = 1250, AvgResponseTime = 85, SuccessRate = 99.2m, LastError = null },
            new() { Path = "/api/milk-collections", Method = "POST", RequestsPerHour = 320, AvgResponseTime = 120, SuccessRate = 98.8m, LastError = null },
            new() { Path = "/api/sales", Method = "GET", RequestsPerHour = 890, AvgResponseTime = 95, SuccessRate = 99.5m, LastError = null },
            new() { Path = "/api/rate/calculate", Method = "GET", RequestsPerHour = 2100, AvgResponseTime = 45, SuccessRate = 99.8m, LastError = null },
            new() { Path = "/api/test-db", Method = "GET", RequestsPerHour = 150, AvgResponseTime = 200, SuccessRate = 87.5m, LastError = "Connection timeout" }
        };

        // Sample system logs
        SystemLogs = new List<SystemLog>
        {
            new() { Timestamp = DateTime.Now.AddMinutes(-1), Level = "Info", Source = "Application", Message = "User login successful for admin@dairy.com" },
            new() { Timestamp = DateTime.Now.AddMinutes(-3), Level = "Warning", Source = "Database", Message = "Query execution time exceeded 500ms for milk collection report" },
            new() { Timestamp = DateTime.Now.AddMinutes(-5), Level = "Info", Source = "API", Message = "Rate calculation completed for farmer ID 1001" },
            new() { Timestamp = DateTime.Now.AddMinutes(-7), Level = "Error", Source = "Hardware", Message = "RFID reader connection timeout - retrying" },
            new() { Timestamp = DateTime.Now.AddMinutes(-10), Level = "Info", Source = "Scheduler", Message = "Daily backup completed successfully" },
            new() { Timestamp = DateTime.Now.AddMinutes(-12), Level = "Debug", Source = "Cache", Message = "Cache refresh completed for rate slabs" },
            new() { Timestamp = DateTime.Now.AddMinutes(-15), Level = "Warning", Source = "Memory", Message = "Memory usage reached 70% threshold" },
            new() { Timestamp = DateTime.Now.AddMinutes(-18), Level = "Info", Source = "Application", Message = "Milk collection record created for farmer ID 1005" }
        };

        // Sample alerts
        Alerts = new List<SystemAlert>
        {
            new() { Id = 1, Title = "High Memory Usage", Message = "System memory usage has exceeded 70% for the last 10 minutes", Severity = "Warning", Timestamp = DateTime.Now.AddMinutes(-8) },
            new() { Id = 2, Title = "API Endpoint Degraded", Message = "Database test endpoint showing increased error rate", Severity = "Warning", Timestamp = DateTime.Now.AddMinutes(-15) }
        };

        // Generate sample response time history (last 24 hours)
        ResponseTimeHistory = new List<ResponseTimePoint>();
        for (int i = 23; i >= 0; i--)
        {
            var time = DateTime.Now.AddHours(-i);
            var baseTime = 120;
            var variation = new Random().Next(-30, 50);
            ResponseTimeHistory.Add(new ResponseTimePoint { Time = time, Value = baseTime + variation });
        }

        // Generate sample resource history (last 24 hours)
        ResourceHistory = new List<ResourcePoint>();
        for (int i = 23; i >= 0; i--)
        {
            var time = DateTime.Now.AddHours(-i);
            var baseCpu = 35;
            var baseMemory = 68;
            var cpuVariation = new Random().Next(-15, 25);
            var memoryVariation = new Random().Next(-10, 15);
            
            ResourceHistory.Add(new ResourcePoint 
            { 
                Time = time, 
                CpuUsage = Math.Max(0, Math.Min(100, baseCpu + cpuVariation)),
                MemoryUsage = Math.Max(0, Math.Min(100, baseMemory + memoryVariation))
            });
        }
    }
}

public class DatabaseMetric
{
    public string MetricName { get; set; } = "";
    public decimal CurrentValue { get; set; }
    public decimal Threshold { get; set; }
    public string Unit { get; set; } = "";
    public string Status { get; set; } = "";
    public DateTime LastUpdated { get; set; }
}

public class ApiEndpoint
{
    public string Path { get; set; } = "";
    public string Method { get; set; } = "";
    public int RequestsPerHour { get; set; }
    public int AvgResponseTime { get; set; }
    public decimal SuccessRate { get; set; }
    public string? LastError { get; set; }
}

public class SystemLog
{
    public DateTime Timestamp { get; set; }
    public string Level { get; set; } = "";
    public string Source { get; set; } = "";
    public string Message { get; set; } = "";
}

public class SystemAlert
{
    public int Id { get; set; }
    public string Title { get; set; } = "";
    public string Message { get; set; } = "";
    public string Severity { get; set; } = "";
    public DateTime Timestamp { get; set; }
}

public class ResponseTimePoint
{
    public DateTime Time { get; set; }
    public int Value { get; set; }
}

public class ResourcePoint
{
    public DateTime Time { get; set; }
    public int CpuUsage { get; set; }
    public int MemoryUsage { get; set; }
}