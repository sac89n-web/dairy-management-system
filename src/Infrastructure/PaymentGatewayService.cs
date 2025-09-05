using System.Text.Json;

namespace Dairy.Infrastructure;

public class PaymentGatewayService : IPaymentGatewayService
{
    private readonly HttpClient _httpClient;
    private readonly string _apiKey = "rzp_test_1234567890"; // Razorpay test key

    public PaymentGatewayService(HttpClient httpClient)
    {
        _httpClient = httpClient;
    }

    public async Task<PaymentResult> InitiatePayoutAsync(PayoutRequest request)
    {
        // Simulate Razorpay payout API call
        await Task.Delay(1500);
        
        var transactionId = "payout_" + DateTime.Now.Ticks;
        
        // Simulate success/failure based on amount
        var success = request.Amount <= 50000; // Simulate failure for large amounts
        
        return new PaymentResult
        {
            Success = success,
            TransactionId = transactionId,
            Status = success ? "PENDING" : "FAILED",
            Message = success ? "Payout initiated successfully" : "Insufficient balance or invalid account",
            Amount = request.Amount,
            Charges = request.Amount * 0.005m, // 0.5% charges
            InitiatedAt = DateTime.Now
        };
    }

    public async Task<PaymentStatus> GetPaymentStatusAsync(string transactionId)
    {
        // Simulate status check API call
        await Task.Delay(500);
        
        // Simulate different statuses based on transaction age
        var statuses = new[] { "PENDING", "SUCCESS", "FAILED" };
        var randomStatus = statuses[new Random().Next(statuses.Length)];
        
        return new PaymentStatus
        {
            TransactionId = transactionId,
            Status = randomStatus,
            BankReferenceNumber = randomStatus == "SUCCESS" ? "UTR" + DateTime.Now.Ticks : "",
            CompletedAt = randomStatus != "PENDING" ? DateTime.Now : null,
            FailureReason = randomStatus == "FAILED" ? "Account not found" : ""
        };
    }

    public async Task<bool> ProcessWebhookAsync(string payload, string signature)
    {
        // Simulate webhook processing
        await Task.Delay(100);
        
        try
        {
            var webhookData = JsonSerializer.Deserialize<Dictionary<string, object>>(payload);
            // Process webhook data and update payment status
            return true;
        }
        catch
        {
            return false;
        }
    }

    public async Task<List<PaymentTransaction>> GetTransactionHistoryAsync(DateTime fromDate, DateTime toDate)
    {
        // Simulate transaction history API call
        await Task.Delay(800);
        
        return new List<PaymentTransaction>
        {
            new PaymentTransaction
            {
                TransactionId = "pout_123456789",
                FarmerId = "F001",
                Amount = 15000.00m,
                Status = "SUCCESS",
                CreatedAt = DateTime.Now.AddDays(-1),
                CompletedAt = DateTime.Now.AddDays(-1).AddMinutes(5)
            },
            new PaymentTransaction
            {
                TransactionId = "pout_123456790",
                FarmerId = "F002",
                Amount = 8500.00m,
                Status = "PENDING",
                CreatedAt = DateTime.Now.AddHours(-2)
            }
        };
    }
}