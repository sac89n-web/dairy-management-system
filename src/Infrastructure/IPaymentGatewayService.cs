namespace Dairy.Infrastructure;

public interface IPaymentGatewayService
{
    Task<PaymentResult> InitiatePayoutAsync(PayoutRequest request);
    Task<PaymentStatus> GetPaymentStatusAsync(string transactionId);
    Task<bool> ProcessWebhookAsync(string payload, string signature);
    Task<List<PaymentTransaction>> GetTransactionHistoryAsync(DateTime fromDate, DateTime toDate);
}

public class PayoutRequest
{
    public string FarmerId { get; set; } = "";
    public string FarmerName { get; set; } = "";
    public decimal Amount { get; set; }
    public string AccountNumber { get; set; } = "";
    public string IfscCode { get; set; } = "";
    public string Purpose { get; set; } = "";
    public string ReferenceId { get; set; } = "";
}

public class PaymentResult
{
    public bool Success { get; set; }
    public string TransactionId { get; set; } = "";
    public string Status { get; set; } = "";
    public string Message { get; set; } = "";
    public decimal Amount { get; set; }
    public decimal Charges { get; set; }
    public DateTime InitiatedAt { get; set; }
}

public class PaymentStatus
{
    public string TransactionId { get; set; } = "";
    public string Status { get; set; } = ""; // PENDING, SUCCESS, FAILED, CANCELLED
    public string BankReferenceNumber { get; set; } = "";
    public DateTime? CompletedAt { get; set; }
    public string FailureReason { get; set; } = "";
}

public class PaymentTransaction
{
    public string TransactionId { get; set; } = "";
    public string FarmerId { get; set; } = "";
    public decimal Amount { get; set; }
    public string Status { get; set; } = "";
    public DateTime CreatedAt { get; set; }
    public DateTime? CompletedAt { get; set; }
}