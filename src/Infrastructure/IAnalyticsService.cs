namespace Dairy.Infrastructure;

public interface IAnalyticsService
{
    Task<AnalyticsDashboard> GetDashboardDataAsync(int? branchId = null);
    Task<List<AnalyticsMetric>> GetMetricsAsync(string category, DateTime fromDate, DateTime toDate);
    Task<PredictionResult> GetQualityPredictionAsync(int farmerId);
    Task<PredictionResult> GetPriceForecastAsync(DateTime forecastDate);
    Task<List<FraudAlert>> GetFraudAlertsAsync(string status = "open");
    Task RecordMetricAsync(string metricName, decimal value, string category, int? branchId = null);
}

public class AnalyticsDashboard
{
    public decimal TotalMilkCollection { get; set; }
    public decimal AverageFatPercentage { get; set; }
    public decimal TotalRevenue { get; set; }
    public int ActiveFarmers { get; set; }
    public decimal CollectionEfficiency { get; set; }
    public List<TrendData> ProductionTrend { get; set; } = new();
    public List<TrendData> QualityTrend { get; set; } = new();
    public List<TrendData> RevenueTrend { get; set; } = new();
    public List<BranchPerformance> BranchPerformance { get; set; } = new();
}

public class AnalyticsMetric
{
    public int Id { get; set; }
    public string MetricName { get; set; } = "";
    public decimal MetricValue { get; set; }
    public string MetricType { get; set; } = "";
    public string Category { get; set; } = "";
    public DateTime DateRecorded { get; set; }
    public int? BranchId { get; set; }
}

public class TrendData
{
    public DateTime Date { get; set; }
    public decimal Value { get; set; }
    public string Label { get; set; } = "";
}

public class BranchPerformance
{
    public int BranchId { get; set; }
    public string BranchName { get; set; } = "";
    public decimal Collection { get; set; }
    public decimal Revenue { get; set; }
    public int FarmerCount { get; set; }
    public decimal Efficiency { get; set; }
}

public class PredictionResult
{
    public decimal PredictedValue { get; set; }
    public decimal ConfidenceScore { get; set; }
    public string PredictionType { get; set; } = "";
    public DateTime PredictionDate { get; set; }
    public string ModelVersion { get; set; } = "";
}

public class FraudAlert
{
    public int Id { get; set; }
    public string AlertType { get; set; } = "";
    public string EntityType { get; set; } = "";
    public int EntityId { get; set; }
    public decimal RiskScore { get; set; }
    public string AlertDetails { get; set; } = "";
    public string Status { get; set; } = "";
    public DateTime CreatedAt { get; set; }
}