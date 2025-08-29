using System.IO.Ports;
using System.Text.Json;

namespace Dairy.Infrastructure.HardwareServices;

public class MilkAnalyzerService : IMilkAnalyzerService, IDisposable
{
    private SerialPort? _serialPort;
    
    public bool IsConnected => _serialPort?.IsOpen ?? false;
    public event EventHandler<QualityAnalysisEventArgs>? AnalysisCompleted;

    public async Task<bool> ConnectAsync(string portName, int baudRate = 9600)
    {
        try
        {
            _serialPort = new SerialPort(portName, baudRate, Parity.None, 8, StopBits.One)
            {
                ReadTimeout = 5000,
                WriteTimeout = 2000
            };

            _serialPort.Open();
            
            // Initialize analyzer
            _serialPort.WriteLine("INIT");
            await Task.Delay(2000);
            
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

    public async Task<MilkQualityResult> AnalyzeAsync()
    {
        if (!IsConnected)
        {
            return new MilkQualityResult 
            { 
                IsValid = false, 
                ErrorMessage = "Analyzer not connected" 
            };
        }

        try
        {
            // Send analysis command
            _serialPort!.WriteLine("ANALYZE");
            await Task.Delay(3000); // Analysis takes time
            
            var response = _serialPort.ReadLine();
            var result = ParseAnalysisResult(response);
            
            AnalysisCompleted?.Invoke(this, new QualityAnalysisEventArgs { Result = result });
            
            return result;
        }
        catch (Exception ex)
        {
            return new MilkQualityResult 
            { 
                IsValid = false, 
                ErrorMessage = ex.Message 
            };
        }
    }

    public async Task<bool> CalibrateAsync(MilkQualityStandard standard)
    {
        if (!IsConnected) return false;

        try
        {
            var calibrationData = JsonSerializer.Serialize(standard);
            _serialPort!.WriteLine($"CALIBRATE:{calibrationData}");
            await Task.Delay(5000); // Calibration takes time
            
            var response = _serialPort.ReadLine();
            return response.Contains("OK");
        }
        catch
        {
            return false;
        }
    }

    public async Task<bool> CleanAsync()
    {
        if (!IsConnected) return false;

        try
        {
            _serialPort!.WriteLine("CLEAN");
            await Task.Delay(10000); // Cleaning cycle
            
            var response = _serialPort.ReadLine();
            return response.Contains("CLEAN_COMPLETE");
        }
        catch
        {
            return false;
        }
    }

    private MilkQualityResult ParseAnalysisResult(string response)
    {
        try
        {
            // Expected format: "FAT:4.2,SNF:8.5,DENSITY:1.028,TEMP:25.5"
            var parts = response.Split(',');
            var result = new MilkQualityResult
            {
                Timestamp = DateTime.Now,
                IsValid = true
            };

            foreach (var part in parts)
            {
                var keyValue = part.Split(':');
                if (keyValue.Length == 2)
                {
                    var value = decimal.Parse(keyValue[1]);
                    switch (keyValue[0])
                    {
                        case "FAT":
                            result.FatPercentage = value;
                            break;
                        case "SNF":
                            result.SnfPercentage = value;
                            break;
                        case "DENSITY":
                            result.Density = value;
                            break;
                        case "TEMP":
                            result.Temperature = value;
                            break;
                    }
                }
            }

            return result;
        }
        catch
        {
            return new MilkQualityResult 
            { 
                IsValid = false, 
                ErrorMessage = "Invalid response format" 
            };
        }
    }

    public void Dispose()
    {
        DisconnectAsync().Wait();
    }
}