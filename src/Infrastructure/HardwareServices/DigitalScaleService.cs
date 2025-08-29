using System.IO.Ports;
using System.Text.RegularExpressions;

namespace Dairy.Infrastructure.HardwareServices;

public class DigitalScaleService : IDigitalScaleService, IDisposable
{
    private SerialPort? _serialPort;
    private Timer? _weightTimer;
    private decimal _lastWeight;
    private int _stableReadings;
    private const int STABLE_THRESHOLD = 3;

    public bool IsConnected => _serialPort?.IsOpen ?? false;
    public event EventHandler<WeightChangedEventArgs>? WeightChanged;

    public async Task<bool> ConnectAsync(string portName, int baudRate = 9600)
    {
        try
        {
            _serialPort = new SerialPort(portName, baudRate, Parity.None, 8, StopBits.One)
            {
                ReadTimeout = 1000,
                WriteTimeout = 1000
            };

            _serialPort.Open();
            
            // Start weight monitoring
            _weightTimer = new Timer(ReadWeightCallback, null, 0, 500);
            
            return true;
        }
        catch
        {
            return false;
        }
    }

    public async Task DisconnectAsync()
    {
        _weightTimer?.Dispose();
        _serialPort?.Close();
        _serialPort?.Dispose();
    }

    public async Task<decimal> GetWeightAsync()
    {
        if (!IsConnected) return 0;

        try
        {
            _serialPort!.WriteLine("W"); // Weight command
            await Task.Delay(100);
            
            var response = _serialPort.ReadLine();
            return ParseWeight(response);
        }
        catch
        {
            return 0;
        }
    }

    public async Task<bool> TareAsync()
    {
        if (!IsConnected) return false;

        try
        {
            _serialPort!.WriteLine("T"); // Tare command
            await Task.Delay(500);
            return true;
        }
        catch
        {
            return false;
        }
    }

    public async Task<bool> CalibrateAsync(decimal knownWeight)
    {
        if (!IsConnected) return false;

        try
        {
            _serialPort!.WriteLine($"C{knownWeight}"); // Calibrate command
            await Task.Delay(2000);
            return true;
        }
        catch
        {
            return false;
        }
    }

    private void ReadWeightCallback(object? state)
    {
        if (!IsConnected) return;

        try
        {
            var weight = GetWeightAsync().Result;
            var isStable = Math.Abs(weight - _lastWeight) < 0.01m;
            
            if (isStable)
                _stableReadings++;
            else
                _stableReadings = 0;

            _lastWeight = weight;

            WeightChanged?.Invoke(this, new WeightChangedEventArgs
            {
                Weight = weight,
                IsStable = _stableReadings >= STABLE_THRESHOLD,
                Timestamp = DateTime.Now
            });
        }
        catch { }
    }

    private decimal ParseWeight(string response)
    {
        var match = Regex.Match(response, @"[\d.]+");
        return match.Success ? decimal.Parse(match.Value) : 0;
    }

    public void Dispose()
    {
        DisconnectAsync().Wait();
    }
}