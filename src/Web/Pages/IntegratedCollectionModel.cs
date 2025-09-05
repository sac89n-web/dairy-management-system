using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.RazorPages;
using Dairy.Infrastructure;
using Dairy.Infrastructure.HardwareServices;

public class IntegratedCollectionModel : PageModel
{
    private readonly HardwareRepository _hardwareRepository;
    private readonly IHardwareIntegrationService _hardwareService;

    public IntegratedCollectionModel(
        HardwareRepository hardwareRepository,
        IHardwareIntegrationService hardwareService)
    {
        _hardwareRepository = hardwareRepository;
        _hardwareService = hardwareService;
    }

    public List<HardwareDevice> HardwareDevices { get; set; } = new();
    public List<RfidCard> RfidCards { get; set; } = new();
    public bool IsHardwareReady => _hardwareService.IsHardwareReady;

    public async Task OnGetAsync()
    {
        HardwareDevices = await _hardwareRepository.GetHardwareDevicesAsync();
        RfidCards = await _hardwareRepository.GetRfidCardsAsync();
    }

    public async Task<IActionResult> OnPostSaveSessionAsync(
        string sessionId, string farmerId, decimal quantity, 
        decimal fat, decimal snf, decimal rate, decimal amount,
        decimal density, decimal temperature, string rfidCardId)
    {
        var session = new HardwareCollectionSession
        {
            SessionId = sessionId,
            FarmerId = farmerId,
            Date = DateTime.Now,
            Quantity = quantity,
            FatPercentage = fat,
            SnfPercentage = snf,
            Rate = rate,
            Amount = amount,
            Density = density,
            Temperature = temperature,
            RfidCardId = rfidCardId
        };

        var collectionId = await _hardwareRepository.SaveCollectionSessionAsync(session);
        
        return new JsonResult(new { success = true, collectionId });
    }
}