namespace Dairy.Infrastructure;

public interface IBranchManagementService
{
    Task<List<Branch>> GetBranchHierarchyAsync();
    Task<Branch> GetBranchAsync(int branchId);
    Task<List<InterBranchTransfer>> GetTransfersAsync(int? branchId = null);
    Task<InterBranchTransfer> CreateTransferAsync(CreateTransferRequest request);
    Task<bool> ApproveTransferAsync(int transferId, int approvedBy);
    Task<ConsolidatedReport> GetConsolidatedReportAsync(DateTime fromDate, DateTime toDate);
}

public class Branch
{
    public int Id { get; set; }
    public string BranchCode { get; set; } = "";
    public string BranchName { get; set; } = "";
    public int? ParentBranchId { get; set; }
    public string BranchType { get; set; } = "";
    public string Address { get; set; } = "";
    public string ContactPerson { get; set; } = "";
    public string Phone { get; set; } = "";
    public string Email { get; set; } = "";
    public bool IsActive { get; set; }
    public List<Branch> SubBranches { get; set; } = new();
    public BranchStats Stats { get; set; } = new();
}

public class BranchStats
{
    public int FarmerCount { get; set; }
    public int CustomerCount { get; set; }
    public decimal TodayCollection { get; set; }
    public decimal MonthlyRevenue { get; set; }
    public int ActiveUsers { get; set; }
}

public class InterBranchTransfer
{
    public int Id { get; set; }
    public string TransferNumber { get; set; } = "";
    public int FromBranchId { get; set; }
    public string FromBranchName { get; set; } = "";
    public int ToBranchId { get; set; }
    public string ToBranchName { get; set; } = "";
    public string TransferType { get; set; } = "";
    public decimal? Quantity { get; set; }
    public decimal? Amount { get; set; }
    public string Status { get; set; } = "";
    public DateTime TransferDate { get; set; }
    public DateTime? ReceivedDate { get; set; }
    public string Notes { get; set; } = "";
    public int CreatedBy { get; set; }
}

public class CreateTransferRequest
{
    public int FromBranchId { get; set; }
    public int ToBranchId { get; set; }
    public string TransferType { get; set; } = "";
    public decimal? Quantity { get; set; }
    public decimal? Amount { get; set; }
    public DateTime TransferDate { get; set; }
    public string Notes { get; set; } = "";
    public int CreatedBy { get; set; }
}

public class ConsolidatedReport
{
    public DateTime FromDate { get; set; }
    public DateTime ToDate { get; set; }
    public decimal TotalCollection { get; set; }
    public decimal TotalRevenue { get; set; }
    public int TotalFarmers { get; set; }
    public List<BranchSummary> BranchSummaries { get; set; } = new();
    public List<TransferSummary> TransferSummaries { get; set; } = new();
}

public class BranchSummary
{
    public string BranchName { get; set; } = "";
    public decimal Collection { get; set; }
    public decimal Revenue { get; set; }
    public int FarmerCount { get; set; }
    public decimal AverageQuality { get; set; }
}

public class TransferSummary
{
    public string TransferType { get; set; } = "";
    public int TransferCount { get; set; }
    public decimal TotalAmount { get; set; }
    public decimal TotalQuantity { get; set; }
}