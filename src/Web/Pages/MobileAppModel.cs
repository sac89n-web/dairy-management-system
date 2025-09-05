using Microsoft.AspNetCore.Mvc.RazorPages;
using Dairy.Infrastructure;

public class MobileAppModel : PageModel
{
    private readonly IMobileAppService _mobileAppService;

    public MobileAppModel(IMobileAppService mobileAppService)
    {
        _mobileAppService = mobileAppService;
    }

    public List<MobileUser> MobileUsers { get; set; } = new();
    public MobileDashboard Dashboard { get; set; } = new();

    public async Task OnGetAsync()
    {
        try
        {
            MobileUsers = await _mobileAppService.GetActiveUsersAsync();
            Dashboard = await _mobileAppService.GetMobileDashboardAsync(1); // Sample user
        }
        catch (Exception ex)
        {
            Console.WriteLine($"Mobile app page error: {ex.Message}");
        }
    }
}