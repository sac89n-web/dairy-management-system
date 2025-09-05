using Dapper;
using Npgsql;

namespace Dairy.Infrastructure;

public class HardwareRepository
{
    private readonly SqlConnectionFactory _connectionFactory;

    public HardwareRepository(SqlConnectionFactory connectionFactory)
    {
        _connectionFactory = connectionFactory;
    }

    public async Task<int> SaveCollectionSessionAsync(HardwareCollectionSession session)
    {
        using var connection = (NpgsqlConnection)_connectionFactory.CreateConnection();
        await connection.OpenAsync();

        var sql = @"
            INSERT INTO dairy.milk_collection 
            (farmer_id, date, qty_ltr, fat_pct, snf_pct, price_per_ltr, due_amt, 
             density, temperature, session_id, rfid_card_id, created_at)
            VALUES (@FarmerId, @Date, @Quantity, @FatPct, @SnfPct, @Rate, @Amount,
                    @Density, @Temperature, @SessionId, @RfidCardId, @CreatedAt)
            RETURNING id";

        return await connection.QuerySingleAsync<int>(sql, new
        {
            FarmerId = session.FarmerId,
            Date = session.Date,
            Quantity = session.Quantity,
            FatPct = session.FatPercentage,
            SnfPct = session.SnfPercentage,
            Rate = session.Rate,
            Amount = session.Amount,
            Density = session.Density,
            Temperature = session.Temperature,
            SessionId = session.SessionId,
            RfidCardId = session.RfidCardId,
            CreatedAt = DateTime.Now
        });
    }

    public async Task<List<HardwareDevice>> GetHardwareDevicesAsync()
    {
        try
        {
            using var connection = (NpgsqlConnection)_connectionFactory.CreateConnection();
            await connection.OpenAsync();

            var sql = @"
                SELECT device_id, device_type, port_name, baud_rate, is_connected, 
                       last_connected, configuration
                FROM dairy.hardware_devices 
                ORDER BY device_type";

            var devices = await connection.QueryAsync<HardwareDevice>(sql);
            return devices.ToList();
        }
        catch
        {
            // Return empty list if table doesn't exist
            return new List<HardwareDevice>();
        }
    }

    public async Task SaveHardwareConfigAsync(HardwareDevice device)
    {
        using var connection = (NpgsqlConnection)_connectionFactory.CreateConnection();
        await connection.OpenAsync();

        var sql = @"
            INSERT INTO dairy.hardware_devices 
            (device_id, device_type, port_name, baud_rate, is_connected, configuration, updated_at)
            VALUES (@DeviceId, @DeviceType, @PortName, @BaudRate, @IsConnected, @Configuration, @UpdatedAt)
            ON CONFLICT (device_id) 
            DO UPDATE SET 
                port_name = @PortName,
                baud_rate = @BaudRate,
                is_connected = @IsConnected,
                configuration = @Configuration,
                updated_at = @UpdatedAt";

        await connection.ExecuteAsync(sql, new
        {
            DeviceId = device.DeviceId,
            DeviceType = device.DeviceType,
            PortName = device.PortName,
            BaudRate = device.BaudRate,
            IsConnected = device.IsConnected,
            Configuration = device.Configuration,
            UpdatedAt = DateTime.Now
        });
    }

    public async Task<List<RfidCard>> GetRfidCardsAsync()
    {
        try
        {
            using var connection = (NpgsqlConnection)_connectionFactory.CreateConnection();
            await connection.OpenAsync();

            var sql = @"
                SELECT card_id, farmer_id, farmer_name, is_active, created_at, last_used
                FROM dairy.rfid_cards 
                WHERE is_active = true
                ORDER BY farmer_name";

            var cards = await connection.QueryAsync<RfidCard>(sql);
            return cards.ToList();
        }
        catch
        {
            // Return empty list if table doesn't exist
            return new List<RfidCard>();
        }
    }

    public async Task SaveRfidCardAsync(RfidCard card)
    {
        using var connection = (NpgsqlConnection)_connectionFactory.CreateConnection();
        await connection.OpenAsync();

        var sql = @"
            INSERT INTO dairy.rfid_cards 
            (card_id, farmer_id, farmer_name, is_active, created_at)
            VALUES (@CardId, @FarmerId, @FarmerName, @IsActive, @CreatedAt)
            ON CONFLICT (card_id) 
            DO UPDATE SET 
                farmer_id = @FarmerId,
                farmer_name = @FarmerName,
                is_active = @IsActive";

        await connection.ExecuteAsync(sql, new
        {
            CardId = card.CardId,
            FarmerId = card.FarmerId,
            FarmerName = card.FarmerName,
            IsActive = card.IsActive,
            CreatedAt = DateTime.Now
        });
    }
}

public class HardwareCollectionSession
{
    public string SessionId { get; set; } = "";
    public string FarmerId { get; set; } = "";
    public DateTime Date { get; set; }
    public decimal Quantity { get; set; }
    public decimal FatPercentage { get; set; }
    public decimal SnfPercentage { get; set; }
    public decimal Rate { get; set; }
    public decimal Amount { get; set; }
    public decimal Density { get; set; }
    public decimal Temperature { get; set; }
    public string RfidCardId { get; set; } = "";
}

public class HardwareDevice
{
    public string DeviceId { get; set; } = "";
    public string DeviceType { get; set; } = "";
    public string PortName { get; set; } = "";
    public int BaudRate { get; set; }
    public bool IsConnected { get; set; }
    public DateTime? LastConnected { get; set; }
    public string? Configuration { get; set; }
}

public class RfidCard
{
    public string CardId { get; set; } = "";
    public string FarmerId { get; set; } = "";
    public string FarmerName { get; set; } = "";
    public bool IsActive { get; set; }
    public DateTime CreatedAt { get; set; }
    public DateTime? LastUsed { get; set; }
}