using Dairy.Domain;
using Dapper;
using Npgsql;

namespace Dairy.Infrastructure
{
    public interface IRateEngineService
    {
        Task<RateCalculationResult> CalculateRateAsync(decimal fatPercent, decimal snfPercent, decimal quantity);
        Task<IEnumerable<RateSlab>> GetActiveSlabsAsync();
        Task EnsureDefaultSlabsAsync();
    }

    public class RateEngineService : IRateEngineService
    {
        private readonly SqlConnectionFactory _connectionFactory;

        public RateEngineService(SqlConnectionFactory connectionFactory)
        {
            _connectionFactory = connectionFactory;
        }

        public async Task<RateCalculationResult> CalculateRateAsync(decimal fatPercent, decimal snfPercent, decimal quantity)
        {
            try
            {
                using var connection = (NpgsqlConnection)_connectionFactory.CreateConnection();
                await connection.OpenAsync();
                
                await EnsureTablesExist(connection);

                var slab = await connection.QuerySingleOrDefaultAsync<RateSlab>(@"
                    SELECT * FROM dairy.rate_slabs 
                    WHERE fat_min <= @fat AND fat_max >= @fat 
                    AND snf_min <= @snf AND snf_max >= @snf 
                    AND is_active = true 
                    AND effective_from <= CURRENT_DATE
                    ORDER BY effective_from DESC 
                    LIMIT 1", new { fat = fatPercent, snf = snfPercent });

                if (slab == null)
                {
                    return new RateCalculationResult
                    {
                        IsValid = false,
                        ErrorMessage = $"No rate slab found for FAT: {fatPercent}%, SNF: {snfPercent}%"
                    };
                }

                var finalRate = slab.BaseRate + slab.Incentive;
                
                return new RateCalculationResult
                {
                    Rate = finalRate,
                    BaseRate = slab.BaseRate,
                    Incentive = slab.Incentive,
                    SlabInfo = $"FAT: {slab.FatMin}-{slab.FatMax}%, SNF: {slab.SnfMin}-{slab.SnfMax}%",
                    IsValid = true
                };
            }
            catch (Exception ex)
            {
                return new RateCalculationResult
                {
                    IsValid = false,
                    ErrorMessage = $"Rate calculation error: {ex.Message}"
                };
            }
        }

        public async Task<IEnumerable<RateSlab>> GetActiveSlabsAsync()
        {
            using var connection = (NpgsqlConnection)_connectionFactory.CreateConnection();
            await connection.OpenAsync();
            
            await EnsureTablesExist(connection);
            
            return await connection.QueryAsync<RateSlab>(@"
                SELECT * FROM dairy.rate_slabs 
                WHERE is_active = true 
                ORDER BY effective_from DESC, fat_min");
        }

        public async Task EnsureDefaultSlabsAsync()
        {
            using var connection = (NpgsqlConnection)_connectionFactory.CreateConnection();
            await connection.OpenAsync();
            
            await EnsureTablesExist(connection);
            
            var count = await connection.QuerySingleOrDefaultAsync<int>("SELECT COUNT(*) FROM dairy.rate_slabs");
            if (count == 0)
            {
                await connection.ExecuteAsync(@"
                    INSERT INTO dairy.rate_slabs (fat_min, fat_max, snf_min, snf_max, base_rate, incentive, effective_from) VALUES
                    (3.0, 3.5, 8.0, 8.5, 25.00, 2.00, CURRENT_DATE),
                    (3.5, 4.0, 8.0, 8.5, 28.00, 2.50, CURRENT_DATE),
                    (4.0, 4.5, 8.5, 9.0, 32.00, 3.00, CURRENT_DATE),
                    (4.5, 5.0, 8.5, 9.0, 35.00, 3.50, CURRENT_DATE),
                    (5.0, 6.0, 9.0, 9.5, 38.00, 4.00, CURRENT_DATE)");
            }
        }

        private async Task EnsureTablesExist(NpgsqlConnection connection)
        {
            await connection.ExecuteAsync(@"
                CREATE TABLE IF NOT EXISTS dairy.rate_slabs (
                    id SERIAL PRIMARY KEY,
                    fat_min DECIMAL(4,2) NOT NULL,
                    fat_max DECIMAL(4,2) NOT NULL,
                    snf_min DECIMAL(4,2) NOT NULL,
                    snf_max DECIMAL(4,2) NOT NULL,
                    base_rate DECIMAL(10,2) NOT NULL,
                    incentive DECIMAL(10,2) NOT NULL DEFAULT 0,
                    effective_from DATE NOT NULL,
                    is_active BOOLEAN DEFAULT true,
                    created_at TIMESTAMP DEFAULT NOW()
                )");
        }
    }
}