namespace Dairy.Infrastructure.HardwareServices;

public interface IHardwareIntegrationService
{
    Task<MilkCollectionSession> StartCollectionSessionAsync();
    Task<bool> CompleteCollectionAsync(MilkCollectionSession session);
    Task<bool> PrintReceiptAsync(MilkCollectionSession session);
    bool IsHardwareReady { get; }
}

public class HardwareIntegrationService : IHardwareIntegrationService
{
    private readonly IDigitalScaleService _scaleService;
    private readonly IMilkAnalyzerService _analyzerService;
    private readonly IThermalPrinterService _printerService;
    private readonly IRfidService _rfidService;

    public HardwareIntegrationService(
        IDigitalScaleService scaleService,
        IMilkAnalyzerService analyzerService,
        IThermalPrinterService printerService,
        IRfidService rfidService)
    {
        _scaleService = scaleService;
        _analyzerService = analyzerService;
        _printerService = printerService;
        _rfidService = rfidService;
    }

    public bool IsHardwareReady => 
        _scaleService.IsConnected && 
        _analyzerService.IsConnected && 
        _printerService.IsConnected && 
        _rfidService.IsConnected;

    public async Task<MilkCollectionSession> StartCollectionSessionAsync()
    {
        var session = new MilkCollectionSession
        {
            SessionId = Guid.NewGuid().ToString(),
            StartTime = DateTime.Now
        };

        // Read RFID card for farmer identification
        var cardResult = await _rfidService.ReadCardAsync();
        if (cardResult.Success)
        {
            session.FarmerId = cardResult.FarmerId;
            session.FarmerName = cardResult.FarmerName;
        }

        // Get weight from scale
        session.Weight = await _scaleService.GetWeightAsync();

        // Analyze milk quality
        var qualityResult = await _analyzerService.AnalyzeAsync();
        if (qualityResult.IsValid)
        {
            session.FatPercentage = qualityResult.FatPercentage;
            session.SnfPercentage = qualityResult.SnfPercentage;
            session.Density = qualityResult.Density;
            session.Temperature = qualityResult.Temperature;
        }

        // Calculate rate based on quality
        session.Rate = CalculateRate(session.FatPercentage, session.SnfPercentage);
        session.Amount = session.Weight * session.Rate;

        return session;
    }

    public async Task<bool> CompleteCollectionAsync(MilkCollectionSession session)
    {
        session.EndTime = DateTime.Now;
        session.IsCompleted = true;
        
        // Save to database would happen here
        return true;
    }

    public async Task<bool> PrintReceiptAsync(MilkCollectionSession session)
    {
        var receipt = new MilkCollectionReceipt
        {
            FarmerName = session.FarmerName,
            FarmerCode = session.FarmerId,
            CollectionDate = session.StartTime,
            Quantity = session.Weight,
            FatPercentage = session.FatPercentage,
            SnfPercentage = session.SnfPercentage,
            Rate = session.Rate,
            Amount = session.Amount,
            Shift = "Morning",
            ReceiptNumber = $"R{DateTime.Now:yyyyMMddHHmmss}"
        };

        return await _printerService.PrintReceiptAsync(receipt);
    }

    private decimal CalculateRate(decimal fat, decimal snf)
    {
        decimal baseRate = 35.0m;
        
        // FAT bonus
        if (fat >= 4.0m) baseRate += 10.0m;
        if (fat >= 4.5m) baseRate += 5.0m;
        
        // SNF bonus
        if (snf >= 8.5m) baseRate += 5.0m;
        if (snf >= 9.0m) baseRate += 3.0m;
        
        return baseRate;
    }
}

public class MilkCollectionSession
{
    public string SessionId { get; set; } = "";
    public string FarmerId { get; set; } = "";
    public string FarmerName { get; set; } = "";
    public decimal Weight { get; set; }
    public decimal FatPercentage { get; set; }
    public decimal SnfPercentage { get; set; }
    public decimal Density { get; set; }
    public decimal Temperature { get; set; }
    public decimal Rate { get; set; }
    public decimal Amount { get; set; }
    public DateTime StartTime { get; set; }
    public DateTime? EndTime { get; set; }
    public bool IsCompleted { get; set; }
}