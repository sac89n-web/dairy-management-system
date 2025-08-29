using Dapper;
using Npgsql;

namespace Dairy.Infrastructure
{
    public interface IDashboardService
    {
        Task<DashboardMetrics> GetMetricsAsync();
        Task<IEnumerable<RateAnalytics>> GetRateAnalyticsAsync();
        Task<IEnumerable<QualityTrend>> GetQualityTrendsAsync();
    }

    public class DashboardService : IDashboardService
    {
        private readonly SqlConnectionFactory _connectionFactory;

        public DashboardService(SqlConnectionFactory connectionFactory)
        {
            _connectionFactory = connectionFactory;
        }

        public async Task<DashboardMetrics> GetMetricsAsync()
        {
            using var connection = (NpgsqlConnection)_connectionFactory.CreateConnection();
            await connection.OpenAsync();

            var today = DateTime.Today;
            var weekAgo = today.AddDays(-7);
            var monthAgo = today.AddMonths(-1);

            var metrics = new DashboardMetrics();

            // Today's collection
            metrics.TodayCollection = await connection.QuerySingleOrDefaultAsync<decimal>(
                "SELECT COALESCE(SUM(qty_ltr), 0) FROM dairy.milk_collection WHERE DATE(date) = @today",
                new { today });

            // Today's revenue
            metrics.TodayRevenue = await connection.QuerySingleOrDefaultAsync<decimal>(
                "SELECT COALESCE(SUM(due_amt), 0) FROM dairy.milk_collection WHERE DATE(date) = @today",
                new { today });

            // Average rate today
            metrics.AvgRateToday = await connection.QuerySingleOrDefaultAsync<decimal>(
                "SELECT COALESCE(AVG(price_per_ltr), 0) FROM dairy.milk_collection WHERE DATE(date) = @today",
                new { today });

            // Active farmers this week
            metrics.ActiveFarmers = await connection.QuerySingleOrDefaultAsync<int>(
                "SELECT COUNT(DISTINCT farmer_id) FROM dairy.milk_collection WHERE date >= @weekAgo",
                new { weekAgo });

            // Quality metrics
            metrics.AvgFat = await connection.QuerySingleOrDefaultAsync<decimal>(
                "SELECT COALESCE(AVG(fat_pct), 0) FROM dairy.milk_collection WHERE date >= @weekAgo",
                new { weekAgo });

            // Check if snf_pct column exists
            var hasSnfColumn = await connection.QuerySingleOrDefaultAsync<bool>(@"
                SELECT EXISTS (
                    SELECT 1 FROM information_schema.columns 
                    WHERE table_schema = 'dairy' 
                    AND table_name = 'milk_collection' 
                    AND column_name = 'snf_pct'
                )");
            
            metrics.AvgSnf = hasSnfColumn ? 
                await connection.QuerySingleOrDefaultAsync<decimal>(
                    "SELECT COALESCE(AVG(snf_pct), 0) FROM dairy.milk_collection WHERE date >= @weekAgo",
                    new { weekAgo }) : 8.5m;

            // Growth calculations
            var lastWeekCollection = await connection.QuerySingleOrDefaultAsync<decimal>(
                "SELECT COALESCE(SUM(qty_ltr), 0) FROM dairy.milk_collection WHERE date >= @lastWeekStart AND date < @thisWeekStart",
                new { lastWeekStart = today.AddDays(-14), thisWeekStart = weekAgo });

            var thisWeekCollection = await connection.QuerySingleOrDefaultAsync<decimal>(
                "SELECT COALESCE(SUM(qty_ltr), 0) FROM dairy.milk_collection WHERE date >= @weekAgo",
                new { weekAgo });

            metrics.WeeklyGrowth = lastWeekCollection > 0 ? 
                ((thisWeekCollection - lastWeekCollection) / lastWeekCollection) * 100 : 0;

            return metrics;
        }

        public async Task<IEnumerable<RateAnalytics>> GetRateAnalyticsAsync()
        {
            using var connection = (NpgsqlConnection)_connectionFactory.CreateConnection();
            await connection.OpenAsync();

            var hasSnfColumn = await connection.QuerySingleOrDefaultAsync<bool>(@"
                SELECT EXISTS (
                    SELECT 1 FROM information_schema.columns 
                    WHERE table_schema = 'dairy' 
                    AND table_name = 'milk_collection' 
                    AND column_name = 'snf_pct'
                )");

            var query = hasSnfColumn ? @"
                SELECT 
                    DATE(date) as collection_date,
                    AVG(price_per_ltr) as avg_rate,
                    MIN(price_per_ltr) as min_rate,
                    MAX(price_per_ltr) as max_rate,
                    SUM(qty_ltr) as total_quantity,
                    AVG(fat_pct) as avg_fat,
                    AVG(snf_pct) as avg_snf
                FROM dairy.milk_collection 
                WHERE date >= CURRENT_DATE - INTERVAL '30 days'
                GROUP BY DATE(date)
                ORDER BY collection_date DESC" : @"
                SELECT 
                    DATE(date) as collection_date,
                    AVG(price_per_ltr) as avg_rate,
                    MIN(price_per_ltr) as min_rate,
                    MAX(price_per_ltr) as max_rate,
                    SUM(qty_ltr) as total_quantity,
                    AVG(fat_pct) as avg_fat,
                    8.5 as avg_snf
                FROM dairy.milk_collection 
                WHERE date >= CURRENT_DATE - INTERVAL '30 days'
                GROUP BY DATE(date)
                ORDER BY collection_date DESC";

            return await connection.QueryAsync<RateAnalytics>(query);
        }

        public async Task<IEnumerable<QualityTrend>> GetQualityTrendsAsync()
        {
            using var connection = (NpgsqlConnection)_connectionFactory.CreateConnection();
            await connection.OpenAsync();

            var hasSnfColumn = await connection.QuerySingleOrDefaultAsync<bool>(@"
                SELECT EXISTS (
                    SELECT 1 FROM information_schema.columns 
                    WHERE table_schema = 'dairy' 
                    AND table_name = 'milk_collection' 
                    AND column_name = 'snf_pct'
                )");

            var query = hasSnfColumn ? @"
                SELECT 
                    DATE(date) as trend_date,
                    AVG(fat_pct) as avg_fat,
                    AVG(snf_pct) as avg_snf,
                    COUNT(*) as sample_count,
                    SUM(qty_ltr) as total_volume
                FROM dairy.milk_collection 
                WHERE date >= CURRENT_DATE - INTERVAL '14 days'
                GROUP BY DATE(date)
                ORDER BY trend_date" : @"
                SELECT 
                    DATE(date) as trend_date,
                    AVG(fat_pct) as avg_fat,
                    8.5 as avg_snf,
                    COUNT(*) as sample_count,
                    SUM(qty_ltr) as total_volume
                FROM dairy.milk_collection 
                WHERE date >= CURRENT_DATE - INTERVAL '14 days'
                GROUP BY DATE(date)
                ORDER BY trend_date";

            return await connection.QueryAsync<QualityTrend>(query);
        }
    }

    public class DashboardMetrics
    {
        public decimal TodayCollection { get; set; }
        public decimal TodayRevenue { get; set; }
        public decimal AvgRateToday { get; set; }
        public int ActiveFarmers { get; set; }
        public decimal AvgFat { get; set; }
        public decimal AvgSnf { get; set; }
        public decimal WeeklyGrowth { get; set; }
    }

    public class RateAnalytics
    {
        public DateTime collection_date { get; set; }
        public decimal avg_rate { get; set; }
        public decimal min_rate { get; set; }
        public decimal max_rate { get; set; }
        public decimal total_quantity { get; set; }
        public decimal avg_fat { get; set; }
        public decimal avg_snf { get; set; }
    }

    public class QualityTrend
    {
        public DateTime trend_date { get; set; }
        public decimal avg_fat { get; set; }
        public decimal avg_snf { get; set; }
        public int sample_count { get; set; }
        public decimal total_volume { get; set; }
    }
}