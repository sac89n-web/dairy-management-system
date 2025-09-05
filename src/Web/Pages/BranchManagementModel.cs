using Microsoft.AspNetCore.Mvc.RazorPages;
using Dairy.Infrastructure;

public class BranchManagementModel : PageModel
{
    private readonly IBranchManagementService _branchService;

    public BranchManagementModel(IBranchManagementService branchService)
    {
        _branchService = branchService;
    }

    public List<Dairy.Infrastructure.Branch> Branches { get; set; } = new();
    public List<InterBranchTransfer> Transfers { get; set; } = new();
    public ConsolidatedReport ConsolidatedReport { get; set; } = new();

    public async Task OnGetAsync(DateTime? fromDate = null, DateTime? toDate = null)
    {
        try
        {
            Branches = await _branchService.GetBranchHierarchyAsync();
            Transfers = await _branchService.GetTransfersAsync();
            
            var reportFromDate = fromDate ?? DateTime.Today.AddDays(-30);
            var reportToDate = toDate ?? DateTime.Today;
            ConsolidatedReport = await _branchService.GetConsolidatedReportAsync(reportFromDate, reportToDate);
        }
        catch (Exception ex)
        {
            Console.WriteLine($"Branch management page error: {ex.Message}");
        }
    }
}