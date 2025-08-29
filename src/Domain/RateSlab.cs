namespace Dairy.Domain
{
    public class RateSlab
    {
        public int Id { get; set; }
        public decimal FatMin { get; set; }
        public decimal FatMax { get; set; }
        public decimal SnfMin { get; set; }
        public decimal SnfMax { get; set; }
        public decimal BaseRate { get; set; }
        public decimal Incentive { get; set; }
        public DateTime EffectiveFrom { get; set; }
        public bool IsActive { get; set; } = true;
        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    }

    public class RateCalculationResult
    {
        public decimal Rate { get; set; }
        public decimal BaseRate { get; set; }
        public decimal Incentive { get; set; }
        public string SlabInfo { get; set; } = "";
        public bool IsValid { get; set; }
        public string ErrorMessage { get; set; } = "";
    }
}