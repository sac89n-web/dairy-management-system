using Microsoft.AspNetCore.Mvc.RazorPages;
using Dairy.Infrastructure;

public class AdvancedAnalyticsModel : PageModel
{
    private readonly IAnalyticsService _analyticsService;
    private readonly IBranchManagementService _branchService;

    public AdvancedAnalyticsModel(IAnalyticsService analyticsService, IBranchManagementService branchService)
    {
        _analyticsService = analyticsService;
        _branchService = branchService;
    }

    public AnalyticsDashboard Dashboard { get; set; } = new();
    public List<Dairy.Infrastructure.Branch> Branches { get; set; } = new();
    public PredictionResult QualityPrediction { get; set; } = new();
    public PredictionResult PriceForecast { get; set; } = new();
    public List<FraudAlert> FraudAlerts { get; set; } = new();

    public async Task OnGetAsync(int? branchId = null)
    {
        try
        {
            Dashboard = await _analyticsService.GetDashboardDataAsync(branchId);
            Branches = await _branchService.GetBranchHierarchyAsync();
            QualityPrediction = await _analyticsService.GetQualityPredictionAsync(1);
            PriceForecast = await _analyticsService.GetPriceForecastAsync(DateTime.Today.AddDays(7));
            FraudAlerts = await _analyticsService.GetFraudAlertsAsync();
        }
        catch (Exception ex)
        {
            // Handle errors gracefully
            Console.WriteLine($"Analytics page error: {ex.Message}");
        }
    }
}