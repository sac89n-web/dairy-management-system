namespace Dairy.Infrastructure.HardwareServices;

public interface IThermalPrinterService
{
    Task<bool> ConnectAsync(string portName, int baudRate = 9600);
    Task DisconnectAsync();
    Task<bool> PrintReceiptAsync(MilkCollectionReceipt receipt);
    Task<bool> PrintReportAsync(string reportContent);
    Task<bool> CutPaperAsync();
    Task<bool> OpenCashDrawerAsync();
    bool IsConnected { get; }
}

public class MilkCollectionReceipt
{
    public string FarmerName { get; set; } = "";
    public string FarmerCode { get; set; } = "";
    public DateTime CollectionDate { get; set; }
    public decimal Quantity { get; set; }
    public decimal FatPercentage { get; set; }
    public decimal SnfPercentage { get; set; }
    public decimal Rate { get; set; }
    public decimal Amount { get; set; }
    public string Shift { get; set; } = "";
    public string ReceiptNumber { get; set; } = "";
}