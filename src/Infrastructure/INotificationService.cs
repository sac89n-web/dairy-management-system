namespace Dairy.Infrastructure;

public interface INotificationService
{
    Task<bool> SendSmsAsync(string phoneNumber, string message);
    Task<bool> SendWhatsAppAsync(string phoneNumber, string message);
    Task<bool> SendEmailAsync(string email, string subject, string body);
    Task<bool> SendCollectionReceiptAsync(string farmerId, CollectionReceiptData data);
    Task<bool> SendPayoutNotificationAsync(string farmerId, PayoutNotificationData data);
    Task<bool> SendQualityAlertAsync(string farmerId, QualityAlertData data);
}

public class CollectionReceiptData
{
    public string FarmerName { get; set; } = "";
    public string FarmerId { get; set; } = "";
    public decimal Quantity { get; set; }
    public decimal FatPercentage { get; set; }
    public decimal SnfPercentage { get; set; }
    public decimal Rate { get; set; }
    public decimal Amount { get; set; }
    public DateTime CollectionDate { get; set; }
    public string ReceiptNumber { get; set; } = "";
}

public class PayoutNotificationData
{
    public string FarmerName { get; set; } = "";
    public decimal Amount { get; set; }
    public string TransactionId { get; set; } = "";
    public string Status { get; set; } = "";
    public DateTime PayoutDate { get; set; }
    public string BankAccount { get; set; } = "";
}

public class QualityAlertData
{
    public string FarmerName { get; set; } = "";
    public decimal FatPercentage { get; set; }
    public decimal SnfPercentage { get; set; }
    public string AlertType { get; set; } = ""; // LOW_QUALITY, ADULTERATION, etc.
    public string Message { get; set; } = "";
    public DateTime AlertDate { get; set; }
}