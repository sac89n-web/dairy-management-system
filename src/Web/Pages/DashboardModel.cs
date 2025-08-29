using Microsoft.AspNetCore.Mvc.RazorPages;
using Dairy.Infrastructure;
using Dapper;
using Npgsql;

public class DashboardModel : BasePageModel
{
    private readonly SqlConnectionFactory _connectionFactory;
    private readonly IDashboardService _dashboardService;
    private readonly IRateEngineService _rateEngine;

    public DashboardModel(SqlConnectionFactory connectionFactory, IDashboardService dashboardService, IRateEngineService rateEngine)
    {
        _connectionFactory = connectionFactory;
        _dashboardService = dashboardService;
        _rateEngine = rateEngine;
    }

    public decimal TodayCollection { get; set; }
    public decimal TodaySales { get; set; }
    public decimal TodayRevenue { get; set; }
    public decimal AvgRateToday { get; set; }
    public int ActiveFarmers { get; set; }
    public decimal AvgFat { get; set; }
    public decimal AvgSnf { get; set; }
    public decimal WeeklyGrowth { get; set; }
    public List<RateAnalytics> RateAnalytics { get; set; } = new();
    public List<QualityTrend> QualityTrends { get; set; } = new();
    public List<RateSlab> ActiveSlabs { get; set; } = new();
    public int LowStockItems { get; set; }
    public int ActiveSubscriptions { get; set; }
    public List<RecentCollection> RecentCollections { get; set; } = new();
    public List<RecentSale> RecentSales { get; set; } = new();
    public List<DashboardTopFarmer> TopFarmers { get; set; } = new();
    public List<MonthlyTrend> MonthlyTrends { get; set; } = new();
    public decimal WeeklyGrowth { get; set; }
    public decimal MonthlyGrowth { get; set; }
    public int PendingPayments { get; set; }
    public decimal AvgFatContent { get; set; }
    public decimal QualityScore { get; set; }
    public decimal TotalOutstanding { get; set; }

    public async Task OnGetAsync()
    {
        using var connection = (NpgsqlConnection)_connectionFactory.CreateConnection();
        
        // Initialize rate engine
        await _rateEngine.EnsureDefaultSlabsAsync();
        
        // Get enhanced metrics
        var metrics = await _dashboardService.GetMetricsAsync();
        TodayCollection = metrics.TodayCollection;
        TodayRevenue = metrics.TodayRevenue;
        AvgRateToday = metrics.AvgRateToday;
        ActiveFarmers = metrics.ActiveFarmers;
        AvgFat = metrics.AvgFat;
        AvgSnf = metrics.AvgSnf;
        WeeklyGrowth = metrics.WeeklyGrowth;
        
        // Get analytics data
        RateAnalytics = (await _dashboardService.GetRateAnalyticsAsync()).ToList();
        QualityTrends = (await _dashboardService.GetQualityTrendsAsync()).ToList();
        ActiveSlabs = (await _rateEngine.GetActiveSlabsAsync()).ToList();
        
        // Sales data
        var today = DateTime.Today;
        TodaySales = await connection.QuerySingleOrDefaultAsync<decimal>(
            "SELECT COALESCE(SUM(qty_ltr), 0) FROM dairy.sale WHERE DATE(date) = @today", 
            new { today });
            
        // Placeholder metrics
        LowStockItems = 0;
        ActiveSubscriptions = 0;

        // Recent collections
        RecentCollections = (await connection.QueryAsync<RecentCollection>(
            "SELECT f.name as farmer_name, mc.qty_ltr as quantity, mc.fat_pct as fat_percentage, mc.due_amt as total_amount FROM dairy.milk_collection mc JOIN dairy.farmer f ON mc.farmer_id = f.id ORDER BY mc.date DESC LIMIT 5")).ToList();

        // Recent sales
        RecentSales = (await connection.QueryAsync<RecentSale>(
            "SELECT c.name as customer_name, s.qty_ltr as quantity, s.unit_price as rate_per_liter, s.paid_amt as total_amount FROM dairy.sale s JOIN dairy.customer c ON s.customer_id = c.id ORDER BY s.date DESC LIMIT 5")).ToList();

        // Top farmers by collection
        TopFarmers = (await connection.QueryAsync<DashboardTopFarmer>(@"
            SELECT f.name, f.code, SUM(mc.qty_ltr) as total_collection, AVG(mc.fat_pct) as avg_fat
            FROM dairy.milk_collection mc
            JOIN dairy.farmer f ON mc.farmer_id = f.id
            WHERE mc.date >= @monthStart
            GROUP BY f.id, f.name, f.code
            ORDER BY total_collection DESC
            LIMIT 5", new { monthStart = new DateTime(today.Year, today.Month, 1) })).ToList();

        // Monthly trends
        MonthlyTrends = (await connection.QueryAsync<MonthlyTrend>(@"
            SELECT DATE_TRUNC('month', date) as month, SUM(qty_ltr) as collection, SUM(due_amt) as revenue
            FROM dairy.milk_collection
            WHERE date >= @sixMonthsAgo
            GROUP BY DATE_TRUNC('month', date)
            ORDER BY month", new { sixMonthsAgo = today.AddMonths(-6) })).ToList();

        // Growth calculations
        var lastWeekCollection = await connection.QuerySingleOrDefaultAsync<decimal>(
            "SELECT COALESCE(SUM(qty_ltr), 0) FROM dairy.milk_collection WHERE date >= @lastWeekStart AND date < @thisWeekStart",
            new { lastWeekStart = today.AddDays(-14), thisWeekStart = today.AddDays(-7) });
        var thisWeekCollection = await connection.QuerySingleOrDefaultAsync<decimal>(
            "SELECT COALESCE(SUM(qty_ltr), 0) FROM dairy.milk_collection WHERE date >= @thisWeekStart",
            new { thisWeekStart = today.AddDays(-7) });
        WeeklyGrowth = lastWeekCollection > 0 ? ((thisWeekCollection - lastWeekCollection) / lastWeekCollection) * 100 : 0;

        // Additional metrics
        PendingPayments = await connection.QuerySingleOrDefaultAsync<int>(
            "SELECT COUNT(*) FROM dairy.milk_collection mc LEFT JOIN dairy.payment_farmer pf ON mc.id = pf.milk_collection_id WHERE pf.id IS NULL");

        AvgFatContent = await connection.QuerySingleOrDefaultAsync<decimal>(
            "SELECT COALESCE(AVG(fat_pct), 0) FROM dairy.milk_collection WHERE date >= @monthStart",
            new { monthStart = new DateTime(today.Year, today.Month, 1) });

        QualityScore = await connection.QuerySingleOrDefaultAsync<decimal>(
            "SELECT COALESCE(AVG(fat_pct), 0) FROM dairy.milk_collection WHERE date >= @monthStart",
            new { monthStart = new DateTime(today.Year, today.Month, 1) });

        TotalOutstanding = await connection.QuerySingleOrDefaultAsync<decimal>(
            "SELECT COALESCE(SUM(mc.due_amt), 0) FROM dairy.milk_collection mc LEFT JOIN dairy.payment_farmer pf ON mc.id = pf.milk_collection_id WHERE pf.id IS NULL");
    }
}

public class RecentCollection
{
    public string farmer_name { get; set; } = "";
    public decimal quantity { get; set; }
    public decimal fat_percentage { get; set; }
    public decimal total_amount { get; set; }
}

public class RecentSale
{
    public string customer_name { get; set; } = "";
    public decimal quantity { get; set; }
    public decimal rate_per_liter { get; set; }
    public decimal total_amount { get; set; }
}

public class DashboardTopFarmer
{
    public string name { get; set; } = "";
    public string code { get; set; } = "";
    public decimal total_collection { get; set; }
    public decimal avg_fat { get; set; }
}

public class MonthlyTrend
{
    public DateTime month { get; set; }
    public decimal collection { get; set; }
    public decimal revenue { get; set; }
}

