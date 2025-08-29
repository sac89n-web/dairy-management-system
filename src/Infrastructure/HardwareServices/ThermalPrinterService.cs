using System.IO.Ports;
using System.Text;

namespace Dairy.Infrastructure.HardwareServices;

public class ThermalPrinterService : IThermalPrinterService, IDisposable
{
    private SerialPort? _serialPort;
    
    // ESC/POS Commands
    private static readonly byte[] ESC = { 0x1B };
    private static readonly byte[] INIT = { 0x1B, 0x40 };
    private static readonly byte[] CUT_PAPER = { 0x1D, 0x56, 0x42, 0x00 };
    private static readonly byte[] OPEN_DRAWER = { 0x1B, 0x70, 0x00, 0x19, 0xFA };
    private static readonly byte[] CENTER_ALIGN = { 0x1B, 0x61, 0x01 };
    private static readonly byte[] LEFT_ALIGN = { 0x1B, 0x61, 0x00 };
    private static readonly byte[] BOLD_ON = { 0x1B, 0x45, 0x01 };
    private static readonly byte[] BOLD_OFF = { 0x1B, 0x45, 0x00 };

    public bool IsConnected => _serialPort?.IsOpen ?? false;

    public async Task<bool> ConnectAsync(string portName, int baudRate = 9600)
    {
        try
        {
            _serialPort = new SerialPort(portName, baudRate, Parity.None, 8, StopBits.One)
            {
                WriteTimeout = 2000
            };

            _serialPort.Open();
            
            // Initialize printer
            _serialPort.Write(INIT, 0, INIT.Length);
            await Task.Delay(500);
            
            return true;
        }
        catch
        {
            return false;
        }
    }

    public async Task DisconnectAsync()
    {
        _serialPort?.Close();
        _serialPort?.Dispose();
    }

    public async Task<bool> PrintReceiptAsync(MilkCollectionReceipt receipt)
    {
        if (!IsConnected) return false;

        try
        {
            var receiptText = GenerateReceiptText(receipt);
            var bytes = Encoding.UTF8.GetBytes(receiptText);
            
            _serialPort!.Write(bytes, 0, bytes.Length);
            await Task.Delay(1000);
            
            return true;
        }
        catch
        {
            return false;
        }
    }

    public async Task<bool> PrintReportAsync(string reportContent)
    {
        if (!IsConnected) return false;

        try
        {
            var bytes = Encoding.UTF8.GetBytes(reportContent);
            _serialPort!.Write(bytes, 0, bytes.Length);
            await Task.Delay(500);
            
            return true;
        }
        catch
        {
            return false;
        }
    }

    public async Task<bool> CutPaperAsync()
    {
        if (!IsConnected) return false;

        try
        {
            _serialPort!.Write(CUT_PAPER, 0, CUT_PAPER.Length);
            await Task.Delay(500);
            return true;
        }
        catch
        {
            return false;
        }
    }

    public async Task<bool> OpenCashDrawerAsync()
    {
        if (!IsConnected) return false;

        try
        {
            _serialPort!.Write(OPEN_DRAWER, 0, OPEN_DRAWER.Length);
            await Task.Delay(200);
            return true;
        }
        catch
        {
            return false;
        }
    }

    private string GenerateReceiptText(MilkCollectionReceipt receipt)
    {
        var sb = new StringBuilder();
        
        // Header
        sb.AppendLine("================================");
        sb.AppendLine("      DAIRY COLLECTION SLIP     ");
        sb.AppendLine("================================");
        sb.AppendLine();
        
        // Receipt details
        sb.AppendLine($"Receipt No: {receipt.ReceiptNumber}");
        sb.AppendLine($"Date: {receipt.CollectionDate:dd/MM/yyyy HH:mm}");
        sb.AppendLine($"Shift: {receipt.Shift}");
        sb.AppendLine();
        
        // Farmer details
        sb.AppendLine($"Farmer: {receipt.FarmerName}");
        sb.AppendLine($"Code: {receipt.FarmerCode}");
        sb.AppendLine();
        
        // Collection details
        sb.AppendLine("--------------------------------");
        sb.AppendLine($"Quantity:     {receipt.Quantity:F2} Ltr");
        sb.AppendLine($"FAT:          {receipt.FatPercentage:F2}%");
        sb.AppendLine($"SNF:          {receipt.SnfPercentage:F2}%");
        sb.AppendLine($"Rate:         ₹{receipt.Rate:F2}/Ltr");
        sb.AppendLine("--------------------------------");
        sb.AppendLine($"TOTAL AMOUNT: ₹{receipt.Amount:F2}");
        sb.AppendLine("================================");
        sb.AppendLine();
        sb.AppendLine("    Thank you for your milk!    ");
        sb.AppendLine();
        sb.AppendLine();
        sb.AppendLine();
        
        return sb.ToString();
    }

    public void Dispose()
    {
        DisconnectAsync().Wait();
    }
}