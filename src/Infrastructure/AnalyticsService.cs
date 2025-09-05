using Dapper;
using System.Data;

namespace Dairy.Infrastructure;

public interface IAdvancedAnalyticsService
{
    Task<DashboardKpis> GetDashboardKpisAsync(DateTime? fromDate = null, DateTime? toDate = null);
    Task<List<FarmerPerformanceReport>> GetFarmerPerformanceReportAsync(DateTime fromDate, DateTime toDate);
    Task<List<QualityTrendReport>> GetQualityTrendReportAsync(DateTime fromDate, DateTime toDate);
    Task<List<PaymentSummaryReport>> GetPaymentSummaryReportAsync(DateTime fromDate, DateTime toDate);
    Task<List<AlertSummary>> GetAlertSummaryAsync();
    Task<byte[]> ExportReportToExcelAsync(string reportType, DateTime fromDate, DateTime toDate);
    Task<bool> ScheduleReportAsync(string reportName, string reportType, string schedule, List<string> recipients);
}

public class AdvancedAnalyticsService : IAdvancedAnalyticsService
{
    private readonly SqlConnectionFactory _connectionFactory;
    public AdvancedAnalyticsService(SqlConnectionFactory connectionFactory)
    {
        _connectionFactory = connectionFactory;
    }

    public async Task<DashboardKpis> GetDashboardKpisAsync(DateTime? fromDate = null, DateTime? toDate = null)
    {
        using var connection = _connectionFactory.CreateConnection();
        
        var from = fromDate ?? DateTime.Today.AddDays(-30);
        var to = toDate ?? DateTime.Today;

        var kpis = await connection.QuerySingleAsync<DashboardKpis>(@"
            SELECT 
                COUNT(DISTINCT f.id) as total_farmers,
                COUNT(DISTINCT c.id) as total_customers,
                COALESCE(SUM(mc.qty_ltr), 0) as total_milk_collected,
                COALESCE(SUM(s.qty_ltr), 0) as total_milk_sold,
                COALESCE(AVG(mc.fat_pct), 0) as avg_fat_percentage,
                COALESCE(AVG(mc.snf_pct), 0) as avg_snf_percentage,
                COALESCE(SUM(mc.due_amt), 0) as total_farmer_dues,
                COALESCE(SUM(s.due_amt), 0) as total_customer_dues,
                COUNT(DISTINCT CASE WHEN mc.date = CURRENT_DATE THEN mc.farmer_id END) as active_farmers_today,
                COUNT(DISTINCT CASE WHEN s.date = CURRENT_DATE THEN s.customer_id END) as active_customers_today
            FROM farmer f
            CROSS JOIN customer c
            LEFT JOIN milk_collection mc ON f.id = mc.farmer_id AND mc.date BETWEEN @FromDate AND @ToDate
            LEFT JOIN sale s ON c.id = s.customer_id AND s.date BETWEEN @FromDate AND @ToDate",
            new { FromDate = from, ToDate = to });

        // Get payment cycle statistics
        var paymentStats = await connection.QuerySingleOrDefaultAsync<dynamic>(@"
            SELECT 
                COUNT(*) as total_cycles,
                COUNT(CASE WHEN status = 'completed' THEN 1 END) as completed_cycles,
                COALESCE(SUM(total_amount), 0) as total_payments_processed
            FROM payment_cycles 
            WHERE start_date >= @FromDate",
            new { FromDate = from });

        kpis.TotalPaymentCycles = paymentStats?.total_cycles ?? 0;
        kpis.CompletedPaymentCycles = paymentStats?.completed_cycles ?? 0;
        kpis.TotalPaymentsProcessed = paymentStats?.total_payments_processed ?? 0;

        // Get quality alerts count
        var alertCount = await connection.QuerySingleOrDefaultAsync<int>(@"
            SELECT COUNT(*) FROM system_alerts 
            WHERE alert_type = 'quality_low' AND is_resolved = false");

        kpis.QualityAlertsCount = alertCount;

        return kpis;
    }

    public async Task<List<FarmerPerformanceReport>> GetFarmerPerformanceReportAsync(DateTime fromDate, DateTime toDate)
    {
        using var connection = _connectionFactory.CreateConnection();
        
        var report = await connection.QueryAsync<FarmerPerformanceReport>(@"
            SELECT 
                f.id as farmer_id,
                f.name as farmer_name,
                f.code as farmer_code,
                COUNT(DISTINCT mc.date) as supply_days,
                COALESCE(SUM(mc.qty_ltr), 0) as total_quantity,
                COALESCE(AVG(mc.qty_ltr), 0) as avg_daily_quantity,
                COALESCE(AVG(mc.fat_pct), 0) as avg_fat_percentage,
                COALESCE(AVG(mc.snf_pct), 0) as avg_snf_percentage,
                COALESCE(SUM(mc.due_amt), 0) as total_amount,
                COALESCE(AVG(mc.price_per_ltr), 0) as avg_rate,
                COUNT(DISTINCT mc.date) * 1.0 / EXTRACT(DAY FROM @ToDate - @FromDate + INTERVAL '1 day') as consistency_score,
                COALESCE(SUM(pcd.bonus_amount), 0) as total_bonus_earned,
                COALESCE(SUM(fa.amount), 0) as total_advances_taken
            FROM farmer f
            LEFT JOIN milk_collection mc ON f.id = mc.farmer_id AND mc.date BETWEEN @FromDate AND @ToDate
            LEFT JOIN payment_cycle_details pcd ON f.id = pcd.farmer_id
            LEFT JOIN farmer_advances fa ON f.id = fa.farmer_id AND fa.disbursed_date BETWEEN @FromDate AND @ToDate
            GROUP BY f.id, f.name, f.code
            ORDER BY total_quantity DESC",
            new { FromDate = fromDate, ToDate = toDate });

        return report.ToList();
    }

    public async Task<List<QualityTrendReport>> GetQualityTrendReportAsync(DateTime fromDate, DateTime toDate)
    {
        using var connection = _connectionFactory.CreateConnection();
        
        var report = await connection.QueryAsync<QualityTrendReport>(@"
            SELECT 
                mc.date,
                s.name as shift_name,
                COUNT(*) as total_collections,
                AVG(mc.fat_pct) as avg_fat_percentage,
                AVG(mc.snf_pct) as avg_snf_percentage,
                MIN(mc.fat_pct) as min_fat_percentage,
                MAX(mc.fat_pct) as max_fat_percentage,
                MIN(mc.snf_pct) as min_snf_percentage,
                MAX(mc.snf_pct) as max_snf_percentage,
                COUNT(CASE WHEN mc.fat_pct < 3.5 THEN 1 END) as low_fat_count,
                COUNT(CASE WHEN mc.snf_pct < 8.5 THEN 1 END) as low_snf_count
            FROM milk_collection mc
            JOIN shift s ON mc.shift_id = s.id
            WHERE mc.date BETWEEN @FromDate AND @ToDate
            GROUP BY mc.date, s.id, s.name
            ORDER BY mc.date DESC, s.name",
            new { FromDate = fromDate, ToDate = toDate });

        return report.ToList();
    }

    public async Task<List<PaymentSummaryReport>> GetPaymentSummaryReportAsync(DateTime fromDate, DateTime toDate)
    {
        using var connection = _connectionFactory.CreateConnection();
        
        var report = await connection.QueryAsync<PaymentSummaryReport>(@"
            SELECT 
                pc.id as cycle_id,
                pc.cycle_name,
                pc.start_date,
                pc.end_date,
                pc.status,
                pc.total_farmers,
                pc.total_amount,
                pc.processed_farmers,
                COUNT(pcd.id) as payment_details_count,
                SUM(pcd.advance_deduction) as total_advance_deductions,
                SUM(pcd.bonus_amount) as total_bonus_paid,
                COUNT(CASE WHEN pcd.payment_status = 'paid' THEN 1 END) as farmers_paid,
                COUNT(CASE WHEN pcd.payment_status = 'pending' THEN 1 END) as farmers_pending
            FROM payment_cycles pc
            LEFT JOIN payment_cycle_details pcd ON pc.id = pcd.cycle_id
            WHERE pc.start_date >= @FromDate AND pc.end_date <= @ToDate
            GROUP BY pc.id, pc.cycle_name, pc.start_date, pc.end_date, pc.status, pc.total_farmers, pc.total_amount, pc.processed_farmers
            ORDER BY pc.start_date DESC",
            new { FromDate = fromDate, ToDate = toDate });

        return report.ToList();
    }

    public async Task<List<AlertSummary>> GetAlertSummaryAsync()
    {
        using var connection = _connectionFactory.CreateConnection();
        
        var alerts = await connection.QueryAsync<AlertSummary>(@"
            SELECT 
                alert_type,
                severity,
                COUNT(*) as total_count,
                COUNT(CASE WHEN is_resolved = false THEN 1 END) as unresolved_count,
                MAX(created_at) as latest_alert_time
            FROM system_alerts
            WHERE created_at >= CURRENT_DATE - INTERVAL '30 days'
            GROUP BY alert_type, severity
            ORDER BY severity DESC, unresolved_count DESC");

        return alerts.ToList();
    }

    public async Task<byte[]> ExportReportToExcelAsync(string reportType, DateTime fromDate, DateTime toDate)
    {
        switch (reportType.ToLower())
        {
            case "farmer_performance":
                var farmerReport = await GetFarmerPerformanceReportAsync(fromDate, toDate);
                return System.Text.Encoding.UTF8.GetBytes("Farmer Performance Report - Excel export not implemented");
                
            case "quality_trend":
                var qualityReport = await GetQualityTrendReportAsync(fromDate, toDate);
                return System.Text.Encoding.UTF8.GetBytes("Quality Trend Report - Excel export not implemented");
                
            case "payment_summary":
                var paymentReport = await GetPaymentSummaryReportAsync(fromDate, toDate);
                return System.Text.Encoding.UTF8.GetBytes("Payment Summary Report - Excel export not implemented");
                
            default:
                throw new ArgumentException("Invalid report type");
        }
    }

    public async Task<bool> ScheduleReportAsync(string reportName, string reportType, string schedule, List<string> recipients)
    {
        using var connection = _connectionFactory.CreateConnection();
        
        var parameters = new
        {
            report_type = reportType,
            from_date = DateTime.Today.AddDays(-30),
            to_date = DateTime.Today
        };

        var id = await connection.QuerySingleAsync<int>(@"
            INSERT INTO report_schedules (report_name, report_type, recipients, schedule_cron, parameters, next_run)
            VALUES (@ReportName, @ReportType, @Recipients, @Schedule, @Parameters, @NextRun)
            RETURNING id",
            new {
                ReportName = reportName,
                ReportType = reportType,
                Recipients = System.Text.Json.JsonSerializer.Serialize(recipients),
                Schedule = schedule,
                Parameters = System.Text.Json.JsonSerializer.Serialize(parameters),
                NextRun = CalculateNextRun(schedule)
            });

        return id > 0;
    }

    private DateTime CalculateNextRun(string cronExpression)
    {
        // Simple cron parsing - implement proper cron parser for production
        return cronExpression switch
        {
            "daily" => DateTime.Today.AddDays(1).AddHours(6),
            "weekly" => DateTime.Today.AddDays(7).AddHours(6),
            "monthly" => DateTime.Today.AddMonths(1).AddHours(6),
            _ => DateTime.Today.AddDays(1).AddHours(6)
        };
    }
}

public class DashboardKpis
{
    public int TotalFarmers { get; set; }
    public int TotalCustomers { get; set; }
    public decimal TotalMilkCollected { get; set; }
    public decimal TotalMilkSold { get; set; }
    public decimal AvgFatPercentage { get; set; }
    public decimal AvgSnfPercentage { get; set; }
    public decimal TotalFarmerDues { get; set; }
    public decimal TotalCustomerDues { get; set; }
    public int ActiveFarmersToday { get; set; }
    public int ActiveCustomersToday { get; set; }
    public int TotalPaymentCycles { get; set; }
    public int CompletedPaymentCycles { get; set; }
    public decimal TotalPaymentsProcessed { get; set; }
    public int QualityAlertsCount { get; set; }
}

public class FarmerPerformanceReport
{
    public int FarmerId { get; set; }
    public string FarmerName { get; set; } = "";
    public string FarmerCode { get; set; } = "";
    public int SupplyDays { get; set; }
    public decimal TotalQuantity { get; set; }
    public decimal AvgDailyQuantity { get; set; }
    public decimal AvgFatPercentage { get; set; }
    public decimal AvgSnfPercentage { get; set; }
    public decimal TotalAmount { get; set; }
    public decimal AvgRate { get; set; }
    public decimal ConsistencyScore { get; set; }
    public decimal TotalBonusEarned { get; set; }
    public decimal TotalAdvancesTaken { get; set; }
}

public class QualityTrendReport
{
    public DateTime Date { get; set; }
    public string ShiftName { get; set; } = "";
    public int TotalCollections { get; set; }
    public decimal AvgFatPercentage { get; set; }
    public decimal AvgSnfPercentage { get; set; }
    public decimal MinFatPercentage { get; set; }
    public decimal MaxFatPercentage { get; set; }
    public decimal MinSnfPercentage { get; set; }
    public decimal MaxSnfPercentage { get; set; }
    public int LowFatCount { get; set; }
    public int LowSnfCount { get; set; }
}

public class PaymentSummaryReport
{
    public int CycleId { get; set; }
    public string CycleName { get; set; } = "";
    public DateTime StartDate { get; set; }
    public DateTime EndDate { get; set; }
    public string Status { get; set; } = "";
    public int TotalFarmers { get; set; }
    public decimal TotalAmount { get; set; }
    public int ProcessedFarmers { get; set; }
    public int PaymentDetailsCount { get; set; }
    public decimal TotalAdvanceDeductions { get; set; }
    public decimal TotalBonusPaid { get; set; }
    public int FarmersPaid { get; set; }
    public int FarmersPending { get; set; }
}

public class AlertSummary
{
    public string AlertType { get; set; } = "";
    public string Severity { get; set; } = "";
    public int TotalCount { get; set; }
    public int UnresolvedCount { get; set; }
    public DateTime LatestAlertTime { get; set; }
}