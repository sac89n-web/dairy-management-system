using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.RazorPages;
using Dairy.Infrastructure;

public class HardwareDataModel : PageModel
{
    private readonly HardwareRepository _hardwareRepository;

    public HardwareDataModel(HardwareRepository hardwareRepository)
    {
        _hardwareRepository = hardwareRepository;
    }

    public List<HardwareDevice> HardwareDevices { get; set; } = new();
    public List<RfidCard> RfidCards { get; set; } = new();

    public async Task OnGetAsync()
    {
        HardwareDevices = await _hardwareRepository.GetHardwareDevicesAsync();
        RfidCards = await _hardwareRepository.GetRfidCardsAsync();
    }

    public async Task<IActionResult> OnPostAddCardAsync(string cardId, string farmerId, string farmerName)
    {
        var card = new RfidCard
        {
            CardId = cardId,
            FarmerId = farmerId,
            FarmerName = farmerName,
            IsActive = true,
            CreatedAt = DateTime.Now
        };

        await _hardwareRepository.SaveRfidCardAsync(card);
        
        return RedirectToPage();
    }
}