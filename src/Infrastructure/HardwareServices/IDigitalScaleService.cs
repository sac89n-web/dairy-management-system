namespace Dairy.Infrastructure.HardwareServices;

public interface IDigitalScaleService
{
    Task<bool> ConnectAsync(string portName, int baudRate = 9600);
    Task DisconnectAsync();
    Task<decimal> GetWeightAsync();
    Task<bool> TareAsync();
    Task<bool> CalibrateAsync(decimal knownWeight);
    bool IsConnected { get; }
    event EventHandler<WeightChangedEventArgs> WeightChanged;
}

public class WeightChangedEventArgs : EventArgs
{
    public decimal Weight { get; set; }
    public bool IsStable { get; set; }
    public DateTime Timestamp { get; set; }
}