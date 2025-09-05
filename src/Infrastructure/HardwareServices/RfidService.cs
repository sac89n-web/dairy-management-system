using System.IO.Ports;
using System.Text.Json;

namespace Dairy.Infrastructure.HardwareServices;

public class RfidService : IRfidService, IDisposable
{
    private SerialPort? _serialPort;
    private Timer? _scanTimer;
    
    public bool IsConnected => _serialPort?.IsOpen ?? false;
    public event EventHandler<CardDetectedEventArgs>? CardDetected;

    public async Task<bool> ConnectAsync(string portName, int baudRate = 9600)
    {
        try
        {
            _serialPort = new SerialPort(portName, baudRate, Parity.None, 8, StopBits.One)
            {
                ReadTimeout = 2000,
                WriteTimeout = 1000
            };

            _serialPort.Open();
            
            // Initialize RFID reader
            _serialPort.WriteLine("INIT");
            await Task.Delay(1000);
            
            // Start continuous scanning
            _scanTimer = new Timer(ScanForCards, null, 0, 1000);
            
            return true;
        }
        catch
        {
            return false;
        }
    }

    public async Task DisconnectAsync()
    {
        _scanTimer?.Dispose();
        _serialPort?.Close();
        _serialPort?.Dispose();
    }

    public async Task<RfidReadResult> ReadCardAsync()
    {
        if (!IsConnected)
        {
            return new RfidReadResult 
            { 
                Success = false, 
                ErrorMessage = "RFID reader not connected" 
            };
        }

        try
        {
            _serialPort!.WriteLine("READ");
            await Task.Delay(500);
            
            var response = _serialPort.ReadLine();
            return ParseCardData(response);
        }
        catch (Exception ex)
        {
            return new RfidReadResult 
            { 
                Success = false, 
                ErrorMessage = ex.Message 
            };
        }
    }

    public async Task<bool> WriteCardAsync(string farmerId, string farmerName)
    {
        if (!IsConnected) return false;

        try
        {
            var cardData = JsonSerializer.Serialize(new { FarmerId = farmerId, FarmerName = farmerName });
            _serialPort!.WriteLine($"WRITE:{cardData}");
            await Task.Delay(2000);
            
            var response = _serialPort.ReadLine();
            return response.Contains("WRITE_OK");
        }
        catch
        {
            return false;
        }
    }

    private void ScanForCards(object? state)
    {
        if (!IsConnected) return;

        try
        {
            var result = ReadCardAsync().Result;
            if (result.Success)
            {
                CardDetected?.Invoke(this, new CardDetectedEventArgs { Result = result });
            }
        }
        catch { }
    }

    private RfidReadResult ParseCardData(string response)
    {
        try
        {
            // Expected format: "CARD:12345678,FARMER:F001,NAME:राहुल पाटील"
            var result = new RfidReadResult
            {
                ReadTime = DateTime.Now,
                Success = true
            };

            var parts = response.Split(',');
            foreach (var part in parts)
            {
                var keyValue = part.Split(':');
                if (keyValue.Length == 2)
                {
                    switch (keyValue[0])
                    {
                        case "CARD":
                            result.CardId = keyValue[1];
                            break;
                        case "FARMER":
                            result.FarmerId = keyValue[1];
                            break;
                        case "NAME":
                            result.FarmerName = keyValue[1];
                            break;
                    }
                }
            }

            return result;
        }
        catch
        {
            return new RfidReadResult 
            { 
                Success = false, 
                ErrorMessage = "Invalid card data format" 
            };
        }
    }

    public void Dispose()
    {
        DisconnectAsync().Wait();
    }
}