namespace Dairy.Infrastructure;

public interface IKycVerificationService
{
    Task<KycVerificationResult> VerifyPanAsync(string panNumber);
    Task<KycVerificationResult> VerifyAadhaarAsync(string aadhaarNumber);
    Task<BankVerificationResult> VerifyBankAccountAsync(string accountNumber, string ifscCode);
    Task<GstVerificationResult> VerifyGstAsync(string gstNumber);
}

public class KycVerificationResult
{
    public bool IsValid { get; set; }
    public string Name { get; set; } = "";
    public string Status { get; set; } = "";
    public string Message { get; set; } = "";
    public DateTime VerifiedAt { get; set; }
}

public class BankVerificationResult
{
    public bool IsValid { get; set; }
    public string AccountHolderName { get; set; } = "";
    public string BankName { get; set; } = "";
    public string BranchName { get; set; } = "";
    public decimal PennyDropAmount { get; set; }
    public string TransactionId { get; set; } = "";
    public string Message { get; set; } = "";
}

public class GstVerificationResult
{
    public bool IsValid { get; set; }
    public string BusinessName { get; set; } = "";
    public string TradeName { get; set; } = "";
    public string Status { get; set; } = "";
    public DateTime RegistrationDate { get; set; }
    public string Message { get; set; } = "";
}