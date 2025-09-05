using Dapper;
using System.Data;
using System.Text.Json;

namespace Dairy.Infrastructure;

public interface IAdvancedNotificationService
{
    Task<bool> SendCollectionReceiptAsync(int farmerId, int collectionId);
    Task<bool> SendPaymentNotificationAsync(int farmerId, int cycleId);
    Task<bool> SendBonusNotificationAsync(int farmerId, int bonusId);
    Task<bool> SendQualityAlertAsync(int farmerId, decimal avgFat, decimal avgSnf);
    Task<bool> SendBulkNotificationsAsync(List<int> farmerIds, string templateType, Dictionary<string, object> parameters);
    Task<List<SystemAlert>> GetUnresolvedAlertsAsync();
    Task<bool> CreateSystemAlertAsync(string alertType, string severity, string entityType, int? entityId, string title, string message);
}

public class AdvancedNotificationService : IAdvancedNotificationService
{
    private readonly SqlConnectionFactory _connectionFactory;
    public AdvancedNotificationService(SqlConnectionFactory connectionFactory)
    {
        _connectionFactory = connectionFactory;
    }

    public async Task<bool> SendCollectionReceiptAsync(int farmerId, int collectionId)
    {
        using var connection = _connectionFactory.CreateConnection();
        
        // Get collection details
        var collection = await connection.QuerySingleOrDefaultAsync<dynamic>(@"
            SELECT 
                mc.*,
                f.name as farmer_name,
                f.contact as farmer_contact,
                s.name as shift_name
            FROM milk_collection mc
            JOIN farmer f ON mc.farmer_id = f.id
            JOIN shift s ON mc.shift_id = s.id
            WHERE mc.id = @CollectionId",
            new { CollectionId = collectionId });

        if (collection == null) return false;

        var parameters = new Dictionary<string, object>
        {
            ["farmer_name"] = collection.farmer_name,
            ["quantity"] = collection.qty_ltr,
            ["fat_percentage"] = collection.fat_pct,
            ["snf_percentage"] = collection.snf_pct ?? 0,
            ["rate"] = collection.price_per_ltr,
            ["amount"] = collection.due_amt,
            ["receipt_number"] = $"RC{collectionId:D6}",
            ["shift"] = collection.shift_name,
            ["date"] = ((DateTime)collection.date).ToString("dd/MM/yyyy")
        };

        return await SendNotificationAsync(farmerId, "collection_receipt", parameters);
    }

    public async Task<bool> SendPaymentNotificationAsync(int farmerId, int cycleId)
    {
        using var connection = _connectionFactory.CreateConnection();
        
        var paymentDetail = await connection.QuerySingleOrDefaultAsync<dynamic>(@"
            SELECT 
                pcd.*,
                f.name as farmer_name,
                f.contact as farmer_contact,
                pc.cycle_name
            FROM payment_cycle_details pcd
            JOIN farmer f ON pcd.farmer_id = f.id
            JOIN payment_cycles pc ON pcd.cycle_id = pc.id
            WHERE pcd.farmer_id = @FarmerId AND pcd.cycle_id = @CycleId",
            new { FarmerId = farmerId, CycleId = cycleId });

        if (paymentDetail == null) return false;

        var parameters = new Dictionary<string, object>
        {
            ["farmer_name"] = paymentDetail.farmer_name,
            ["total_qty"] = paymentDetail.total_milk_qty,
            ["total_amount"] = paymentDetail.total_amount,
            ["advance_deduction"] = paymentDetail.advance_deduction,
            ["final_amount"] = paymentDetail.final_amount,
            ["payment_status"] = paymentDetail.payment_status,
            ["cycle_name"] = paymentDetail.cycle_name
        };

        return await SendNotificationAsync(farmerId, "payment_cycle", parameters);
    }

    public async Task<bool> SendBonusNotificationAsync(int farmerId, int bonusId)
    {
        using var connection = _connectionFactory.CreateConnection();
        
        var bonus = await connection.QuerySingleOrDefaultAsync<dynamic>(@"
            SELECT 
                bc.*,
                f.name as farmer_name,
                f.contact as farmer_contact,
                bcf.config_name
            FROM bonus_calculations bc
            JOIN farmer f ON bc.farmer_id = f.id
            JOIN bonus_configurations bcf ON bc.config_id = bcf.id
            WHERE bc.id = @BonusId",
            new { BonusId = bonusId });

        if (bonus == null) return false;

        var parameters = new Dictionary<string, object>
        {
            ["farmer_name"] = bonus.farmer_name,
            ["period"] = bonus.calculation_period == "half_yearly" ? "छमाही" : "वार्षिक",
            ["bonus_amount"] = bonus.bonus_amount,
            ["bonus_reason"] = bonus.config_name,
            ["total_supply"] = bonus.total_milk_qty,
            ["quality_score"] = $"वसा: {bonus.avg_fat_pct:F1}%, SNF: {bonus.avg_snf_pct:F1}%"
        };

        return await SendNotificationAsync(farmerId, "bonus_payout", parameters);
    }

    public async Task<bool> SendQualityAlertAsync(int farmerId, decimal avgFat, decimal avgSnf)
    {
        var parameters = new Dictionary<string, object>
        {
            ["avg_fat"] = avgFat.ToString("F1"),
            ["avg_snf"] = avgSnf.ToString("F1")
        };

        var sent = await SendNotificationAsync(farmerId, "quality_alert", parameters);
        
        if (sent)
        {
            await CreateSystemAlertAsync(
                "quality_low", 
                "medium", 
                "farmer", 
                farmerId,
                "गुणवत्ता चेतावनी",
                $"किसान ID {farmerId} के दूध की गुणवत्ता कम है - वसा: {avgFat:F1}%, SNF: {avgSnf:F1}%"
            );
        }

        return sent;
    }

    private async Task<bool> SendNotificationAsync(int farmerId, string templateType, Dictionary<string, object> parameters)
    {
        using var connection = _connectionFactory.CreateConnection();
        
        // Get farmer details and preferences
        var farmer = await connection.QuerySingleOrDefaultAsync<dynamic>(@"
            SELECT 
                f.name,
                f.contact,
                COALESCE(np.whatsapp_enabled, true) as whatsapp_enabled,
                COALESCE(np.sms_enabled, true) as sms_enabled,
                COALESCE(np.language_preference, 'hi') as language_preference
            FROM farmer f
            LEFT JOIN notification_preferences np ON f.id = np.farmer_id
            WHERE f.id = @FarmerId",
            new { FarmerId = farmerId });

        if (farmer == null) return false;

        parameters["farmer_name"] = farmer.name;

        // Get notification template
        var template = await connection.QuerySingleOrDefaultAsync<dynamic>(@"
            SELECT * FROM notification_templates 
            WHERE template_type = @TemplateType 
            AND language = @Language 
            AND is_active = true
            ORDER BY id DESC
            LIMIT 1",
            new { 
                TemplateType = templateType, 
                Language = farmer.language_preference 
            });

        if (template == null) return false;

        // Replace template variables
        var message = ReplaceTemplateVariables(template.message_template, parameters);
        
        bool sent = false;

        // Send WhatsApp if enabled
        if (farmer.whatsapp_enabled)
        {
            sent = await SendWhatsAppMessageAsync(farmer.contact, message);
            await LogNotificationAsync(farmerId, "whatsapp", templateType, farmer.contact, message, sent);
        }

        // Send SMS if WhatsApp failed or not enabled
        if (!sent && farmer.sms_enabled)
        {
            sent = await SendSmsMessageAsync(farmer.contact, message);
            await LogNotificationAsync(farmerId, "sms", templateType, farmer.contact, message, sent);
        }

        return sent;
    }

    private string ReplaceTemplateVariables(string template, Dictionary<string, object> parameters)
    {
        foreach (var param in parameters)
        {
            template = template.Replace($"{{{{{param.Key}}}}}", param.Value?.ToString() ?? "");
        }
        return template;
    }

    private async Task<bool> SendWhatsAppMessageAsync(string phoneNumber, string message)
    {
        try
        {
            // Integration with WhatsApp Business API or third-party service
            // This is a placeholder - implement with your preferred WhatsApp service
            
            await Task.Delay(100); // Simulate API call
            
            // Placeholder implementation - replace with actual WhatsApp service
            return true; // Simulate success
        }
        catch
        {
            return false;
        }
    }

    private async Task<bool> SendSmsMessageAsync(string phoneNumber, string message)
    {
        try
        {
            // Integration with SMS service (MSG91, Textlocal, etc.)
            // This is a placeholder - implement with your preferred SMS service
            
            await Task.Delay(100); // Simulate API call
            
            // Placeholder implementation - replace with actual SMS service
            return true; // Simulate success
        }
        catch
        {
            return false;
        }
    }

    private async Task LogNotificationAsync(int farmerId, string channel, string templateType, string phoneNumber, string message, bool sent)
    {
        using var connection = _connectionFactory.CreateConnection();
        
        await connection.ExecuteAsync(@"
            INSERT INTO notification_logs 
            (recipient_type, recipient_id, channel, template_type, phone_number, message_content, status, sent_at)
            VALUES ('farmer', @FarmerId, @Channel, @TemplateType, @PhoneNumber, @Message, @Status, @SentAt)",
            new {
                FarmerId = farmerId.ToString(),
                Channel = channel,
                TemplateType = templateType,
                PhoneNumber = phoneNumber,
                Message = message,
                Status = sent ? "sent" : "failed",
                SentAt = sent ? DateTime.Now : (DateTime?)null
            });
    }

    public async Task<bool> SendBulkNotificationsAsync(List<int> farmerIds, string templateType, Dictionary<string, object> parameters)
    {
        var tasks = farmerIds.Select(farmerId => SendNotificationAsync(farmerId, templateType, parameters));
        var results = await Task.WhenAll(tasks);
        return results.Any(r => r);
    }

    public async Task<List<SystemAlert>> GetUnresolvedAlertsAsync()
    {
        using var connection = _connectionFactory.CreateConnection();
        
        var alerts = await connection.QueryAsync<SystemAlert>(@"
            SELECT * FROM system_alerts 
            WHERE is_resolved = false 
            ORDER BY severity DESC, created_at DESC
            LIMIT 50");

        return alerts.ToList();
    }

    public async Task<bool> CreateSystemAlertAsync(string alertType, string severity, string entityType, int? entityId, string title, string message)
    {
        using var connection = _connectionFactory.CreateConnection();
        
        var id = await connection.QuerySingleAsync<int>(@"
            INSERT INTO system_alerts (alert_type, severity, entity_type, entity_id, title, message)
            VALUES (@AlertType, @Severity, @EntityType, @EntityId, @Title, @Message)
            RETURNING id",
            new {
                AlertType = alertType,
                Severity = severity,
                EntityType = entityType,
                EntityId = entityId,
                Title = title,
                Message = message
            });

        return id > 0;
    }
}

public class SystemAlert
{
    public int Id { get; set; }
    public string AlertType { get; set; } = "";
    public string Severity { get; set; } = "";
    public string EntityType { get; set; } = "";
    public int? EntityId { get; set; }
    public string Title { get; set; } = "";
    public string Message { get; set; } = "";
    public bool IsResolved { get; set; }
    public int? ResolvedBy { get; set; }
    public DateTime? ResolvedAt { get; set; }
    public DateTime CreatedAt { get; set; }
}