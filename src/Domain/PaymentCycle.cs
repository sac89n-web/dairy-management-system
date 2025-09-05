using System.ComponentModel.DataAnnotations;

namespace Dairy.Domain;

public class Farmer
{
    public int Id { get; set; }
    public string Name { get; set; } = "";
    public string Code { get; set; } = "";
    public string Phone { get; set; } = "";
    public string Address { get; set; } = "";
    public bool IsActive { get; set; } = true;
}

public class PaymentCycle
{
    public int Id { get; set; }
    
    [Required]
    public DateTime StartDate { get; set; }
    
    [Required]
    public DateTime EndDate { get; set; }
    
    [Required]
    [StringLength(20)]
    public string Status { get; set; } = "Active"; // Active, Completed, Cancelled
    
    public decimal TotalAmount { get; set; }
    
    public int TotalFarmers { get; set; }
    
    public DateTime? ProcessedDate { get; set; }
    
    public string? ProcessedBy { get; set; }
    
    public DateTime CreatedDate { get; set; } = DateTime.UtcNow;
    
    // Navigation properties
    public virtual ICollection<FarmerPayment> FarmerPayments { get; set; } = new List<FarmerPayment>();
}

public class FarmerPayment
{
    public int Id { get; set; }
    
    [Required]
    public int PaymentCycleId { get; set; }
    
    [Required]
    public int FarmerId { get; set; }
    
    public decimal MilkAmount { get; set; }
    
    public decimal RateAmount { get; set; }
    
    public decimal IncentiveAmount { get; set; }
    
    public decimal AdvanceDeduction { get; set; }
    
    public decimal NetAmount { get; set; }
    
    [StringLength(20)]
    public string PaymentMethod { get; set; } = "Bank"; // Bank, Cash, Mixed
    
    [StringLength(20)]
    public string Status { get; set; } = "Pending"; // Pending, Processed, Failed
    
    public DateTime? PaidDate { get; set; }
    
    public string? TransactionRef { get; set; }
    
    // Navigation properties
    public virtual PaymentCycle PaymentCycle { get; set; } = null!;
    public virtual Farmer Farmer { get; set; } = null!;
}

public class FarmerAdvance
{
    public int Id { get; set; }
    
    [Required]
    public int FarmerId { get; set; }
    
    [Required]
    public decimal Amount { get; set; }
    
    [Required]
    public DateTime AdvanceDate { get; set; }
    
    [StringLength(500)]
    public string? Purpose { get; set; }
    
    [StringLength(20)]
    public string Status { get; set; } = "Active"; // Active, Adjusted, Cancelled
    
    public decimal AdjustedAmount { get; set; } = 0;
    
    public decimal BalanceAmount { get; set; }
    
    public string? ApprovedBy { get; set; }
    
    public DateTime CreatedDate { get; set; } = DateTime.UtcNow;
    
    // Navigation properties
    public virtual Farmer Farmer { get; set; } = null!;
}