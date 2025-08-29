namespace Dairy.Infrastructure.HardwareServices;

public interface IMilkAnalyzerService
{
    Task<bool> ConnectAsync(string portName, int baudRate = 9600);
    Task DisconnectAsync();
    Task<MilkQualityResult> AnalyzeAsync();
    Task<bool> CalibrateAsync(MilkQualityStandard standard);
    Task<bool> CleanAsync();
    bool IsConnected { get; }
    event EventHandler<QualityAnalysisEventArgs> AnalysisCompleted;
}

public class MilkQualityResult
{
    public decimal FatPercentage { get; set; }
    public decimal SnfPercentage { get; set; }
    public decimal Density { get; set; }
    public decimal Temperature { get; set; }
    public DateTime Timestamp { get; set; }
    public bool IsValid { get; set; }
    public string? ErrorMessage { get; set; }
}

public class MilkQualityStandard
{
    public decimal FatPercentage { get; set; }
    public decimal SnfPercentage { get; set; }
    public decimal Density { get; set; }
}

public class QualityAnalysisEventArgs : EventArgs
{
    public MilkQualityResult Result { get; set; } = new();
}