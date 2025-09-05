namespace Dairy.Infrastructure.HardwareServices;

public interface IRfidService
{
    Task<bool> ConnectAsync(string portName, int baudRate = 9600);
    Task DisconnectAsync();
    Task<RfidReadResult> ReadCardAsync();
    Task<bool> WriteCardAsync(string farmerId, string farmerName);
    bool IsConnected { get; }
    event EventHandler<CardDetectedEventArgs> CardDetected;
}

public class RfidReadResult
{
    public bool Success { get; set; }
    public string CardId { get; set; } = "";
    public string FarmerId { get; set; } = "";
    public string FarmerName { get; set; } = "";
    public DateTime ReadTime { get; set; }
    public string? ErrorMessage { get; set; }
}

public class CardDetectedEventArgs : EventArgs
{
    public RfidReadResult Result { get; set; } = new();
}