using Dapper;
using System.Data;
using System.Text.Json;

namespace Dairy.Infrastructure;

public interface IBonusService
{
    Task<List<BonusCalculation>> CalculateHalfYearlyBonusAsync(DateTime periodStart, DateTime periodEnd);
    Task<List<BonusCalculation>> CalculateYearlyBonusAsync(DateTime periodStart, DateTime periodEnd);
    Task<bool> ApproveBonusAsync(int bonusId, int approvedBy);
    Task<bool> ProcessBonusPaymentAsync(int bonusId, int cycleId);
    Task<List<BonusConfiguration>> GetActiveBonusConfigurationsAsync();
}

public class BonusService : IBonusService
{
    private readonly SqlConnectionFactory _connectionFactory;

    public BonusService(SqlConnectionFactory connectionFactory)
    {
        _connectionFactory = connectionFactory;
    }

    public async Task<List<BonusCalculation>> CalculateHalfYearlyBonusAsync(DateTime periodStart, DateTime periodEnd)
    {
        return await CalculateBonusAsync("half_yearly", periodStart, periodEnd);
    }

    public async Task<List<BonusCalculation>> CalculateYearlyBonusAsync(DateTime periodStart, DateTime periodEnd)
    {
        return await CalculateBonusAsync("yearly", periodStart, periodEnd);
    }

    private async Task<List<BonusCalculation>> CalculateBonusAsync(string period, DateTime periodStart, DateTime periodEnd)
    {
        using var connection = _connectionFactory.CreateConnection();
        
        var bonusCalculations = new List<BonusCalculation>();
        
        // Get active bonus configurations
        var configs = await GetActiveBonusConfigurationsAsync();
        
        // Get farmer performance data
        var farmerData = await connection.QueryAsync<dynamic>(@"
            SELECT 
                f.id as farmer_id,
                f.name as farmer_name,
                f.code as farmer_code,
                COUNT(DISTINCT mc.date) as supply_days,
                SUM(mc.qty_ltr) as total_qty,
                AVG(mc.fat_pct) as avg_fat,
                AVG(mc.snf_pct) as avg_snf,
                COUNT(DISTINCT mc.date) * 1.0 / EXTRACT(DAY FROM @PeriodEnd - @PeriodStart + INTERVAL '1 day') as consistency_score
            FROM farmer f
            LEFT JOIN milk_collection mc ON f.id = mc.farmer_id 
                AND mc.date BETWEEN @PeriodStart AND @PeriodEnd
            GROUP BY f.id, f.name, f.code",
            new { PeriodStart = periodStart, PeriodEnd = periodEnd });

        foreach (var farmer in farmerData)
        {
            foreach (var config in configs)
            {
                var bonusAmount = CalculateBonusForFarmer(farmer, config);
                
                if (bonusAmount > 0)
                {
                    var calculation = new BonusCalculation
                    {
                        FarmerId = farmer.farmer_id,
                        ConfigId = config.Id,
                        CalculationPeriod = period,
                        PeriodStart = periodStart,
                        PeriodEnd = periodEnd,
                        TotalMilkQty = farmer.total_qty ?? 0,
                        AvgFatPct = farmer.avg_fat ?? 0,
                        AvgSnfPct = farmer.avg_snf ?? 0,
                        ConsistencyScore = farmer.consistency_score ?? 0,
                        BonusAmount = bonusAmount,
                        Status = "calculated"
                    };

                    // Save to database
                    var id = await connection.QuerySingleAsync<int>(@"
                        INSERT INTO bonus_calculations 
                        (farmer_id, config_id, calculation_period, period_start, period_end, 
                         total_milk_qty, avg_fat_pct, avg_snf_pct, consistency_score, bonus_amount, status)
                        VALUES (@FarmerId, @ConfigId, @CalculationPeriod, @PeriodStart, @PeriodEnd,
                                @TotalMilkQty, @AvgFatPct, @AvgSnfPct, @ConsistencyScore, @BonusAmount, @Status)
                        RETURNING id",
                        calculation);

                    calculation.Id = id;
                    calculation.FarmerName = farmer.farmer_name;
                    calculation.FarmerCode = farmer.farmer_code;
                    bonusCalculations.Add(calculation);
                }
            }
        }

        return bonusCalculations;
    }

    private decimal CalculateBonusForFarmer(dynamic farmerData, BonusConfiguration config)
    {
        var criteria = JsonSerializer.Deserialize<Dictionary<string, object>>(config.Criteria);
        decimal bonusAmount = 0;

        switch (config.BonusType.ToLower())
        {
            case "quality":
                bonusAmount = CalculateQualityBonus(farmerData, criteria, config.CalculationMethod);
                break;
            case "quantity":
                bonusAmount = CalculateQuantityBonus(farmerData, criteria, config.CalculationMethod);
                break;
            case "consistency":
                bonusAmount = CalculateConsistencyBonus(farmerData, criteria, config.CalculationMethod);
                break;
            case "combined":
                bonusAmount = CalculateCombinedBonus(farmerData, criteria, config.CalculationMethod);
                break;
        }

        return bonusAmount;
    }

    private decimal CalculateQualityBonus(dynamic farmerData, Dictionary<string, object> criteria, string method)
    {
        var avgFat = (decimal)(farmerData.avg_fat ?? 0);
        var avgSnf = (decimal)(farmerData.avg_snf ?? 0);
        var totalQty = (decimal)(farmerData.total_qty ?? 0);

        if (criteria.ContainsKey("fat_min") && avgFat < Convert.ToDecimal(criteria["fat_min"]))
            return 0;
        
        if (criteria.ContainsKey("snf_min") && avgSnf < Convert.ToDecimal(criteria["snf_min"]))
            return 0;

        if (method == "slab" && criteria.ContainsKey("slabs"))
        {
            var slabs = JsonSerializer.Deserialize<List<Dictionary<string, object>>>(criteria["slabs"].ToString()!);
            
            foreach (var slab in slabs!.OrderByDescending(s => Convert.ToDecimal(s["min_qty"])))
            {
                if (totalQty >= Convert.ToDecimal(slab["min_qty"]))
                {
                    var bonusPct = Convert.ToDecimal(slab["bonus_pct"]);
                    return totalQty * 50 * bonusPct / 100; // Assuming ₹50 average rate
                }
            }
        }

        return 0;
    }

    private decimal CalculateQuantityBonus(dynamic farmerData, Dictionary<string, object> criteria, string method)
    {
        var totalQty = (decimal)(farmerData.total_qty ?? 0);

        if (method == "slab" && criteria.ContainsKey("slabs"))
        {
            var slabs = JsonSerializer.Deserialize<List<Dictionary<string, object>>>(criteria["slabs"].ToString()!);
            
            foreach (var slab in slabs!.OrderByDescending(s => Convert.ToDecimal(s["min_qty"])))
            {
                if (totalQty >= Convert.ToDecimal(slab["min_qty"]))
                {
                    var bonusPct = Convert.ToDecimal(slab["bonus_pct"]);
                    return totalQty * 50 * bonusPct / 100; // Assuming ₹50 average rate
                }
            }
        }

        return 0;
    }

    private decimal CalculateConsistencyBonus(dynamic farmerData, Dictionary<string, object> criteria, string method)
    {
        var consistencyScore = (decimal)(farmerData.consistency_score ?? 0);
        var totalQty = (decimal)(farmerData.total_qty ?? 0);

        if (criteria.ContainsKey("min_days"))
        {
            var minDays = Convert.ToInt32(criteria["min_days"]);
            var actualDays = (int)(farmerData.supply_days ?? 0);
            
            if (actualDays >= minDays && method == "percentage")
            {
                var bonusPct = Convert.ToDecimal(criteria["bonus_pct"]);
                var calculatedBonus = totalQty * 50 * bonusPct / 100;
                
                if (criteria.ContainsKey("max_bonus"))
                {
                    var maxBonus = Convert.ToDecimal(criteria["max_bonus"]);
                    return Math.Min(calculatedBonus, maxBonus);
                }
                
                return calculatedBonus;
            }
        }

        return 0;
    }

    private decimal CalculateCombinedBonus(dynamic farmerData, Dictionary<string, object> criteria, string method)
    {
        // Implement combined bonus logic based on multiple factors
        var qualityBonus = CalculateQualityBonus(farmerData, criteria, method);
        var quantityBonus = CalculateQuantityBonus(farmerData, criteria, method);
        var consistencyBonus = CalculateConsistencyBonus(farmerData, criteria, method);

        return (qualityBonus + quantityBonus + consistencyBonus) * 0.8m; // 80% of combined
    }

    public async Task<bool> ApproveBonusAsync(int bonusId, int approvedBy)
    {
        using var connection = _connectionFactory.CreateConnection();
        
        var rowsAffected = await connection.ExecuteAsync(@"
            UPDATE bonus_calculations 
            SET status = 'approved', approved_by = @ApprovedBy
            WHERE id = @BonusId AND status = 'calculated'",
            new { BonusId = bonusId, ApprovedBy = approvedBy });

        return rowsAffected > 0;
    }

    public async Task<bool> ProcessBonusPaymentAsync(int bonusId, int cycleId)
    {
        using var connection = _connectionFactory.CreateConnection();
        using var transaction = connection.BeginTransaction();
        
        try
        {
            // Get bonus details
            var bonus = await connection.QuerySingleOrDefaultAsync<BonusCalculation>(@"
                SELECT * FROM bonus_calculations WHERE id = @BonusId AND status = 'approved'",
                new { BonusId = bonusId }, transaction);

            if (bonus == null) return false;

            // Add bonus to payment cycle details
            await connection.ExecuteAsync(@"
                UPDATE payment_cycle_details 
                SET bonus_amount = bonus_amount + @BonusAmount,
                    final_amount = final_amount + @BonusAmount
                WHERE cycle_id = @CycleId AND farmer_id = @FarmerId",
                new { 
                    BonusAmount = bonus.BonusAmount, 
                    CycleId = cycleId, 
                    FarmerId = bonus.FarmerId 
                }, transaction);

            // Mark bonus as paid
            await connection.ExecuteAsync(@"
                UPDATE bonus_calculations 
                SET status = 'paid', paid_in_cycle_id = @CycleId
                WHERE id = @BonusId",
                new { BonusId = bonusId, CycleId = cycleId }, transaction);

            transaction.Commit();
            return true;
        }
        catch
        {
            transaction.Rollback();
            return false;
        }
    }

    public async Task<List<BonusConfiguration>> GetActiveBonusConfigurationsAsync()
    {
        using var connection = _connectionFactory.CreateConnection();
        
        var configs = await connection.QueryAsync<BonusConfiguration>(@"
            SELECT * FROM bonus_configurations 
            WHERE is_active = true 
            AND (effective_to IS NULL OR effective_to >= CURRENT_DATE)
            ORDER BY config_name");

        return configs.ToList();
    }
}

public class BonusCalculation
{
    public int Id { get; set; }
    public int FarmerId { get; set; }
    public string FarmerName { get; set; } = "";
    public string FarmerCode { get; set; } = "";
    public int ConfigId { get; set; }
    public string CalculationPeriod { get; set; } = "";
    public DateTime PeriodStart { get; set; }
    public DateTime PeriodEnd { get; set; }
    public decimal TotalMilkQty { get; set; }
    public decimal AvgFatPct { get; set; }
    public decimal AvgSnfPct { get; set; }
    public decimal ConsistencyScore { get; set; }
    public decimal BonusAmount { get; set; }
    public string Status { get; set; } = "calculated";
    public int? ApprovedBy { get; set; }
    public int? PaidInCycleId { get; set; }
    public DateTime CreatedAt { get; set; }
}

public class BonusConfiguration
{
    public int Id { get; set; }
    public string ConfigName { get; set; } = "";
    public string BonusType { get; set; } = "";
    public string CalculationMethod { get; set; } = "";
    public string Criteria { get; set; } = "";
    public bool IsActive { get; set; }
    public DateTime EffectiveFrom { get; set; }
    public DateTime? EffectiveTo { get; set; }
    public DateTime CreatedAt { get; set; }
}