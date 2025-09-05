using Dapper;
using System.Data;

namespace Dairy.Infrastructure;

public interface IPaymentCycleService
{
    Task<int> CreatePaymentCycleAsync(DateTime startDate, DateTime endDate);
    Task<bool> ProcessPaymentCycleAsync(int cycleId);
    Task<string> GenerateBankFileAsync(int cycleId, string bankName);
    Task<List<PaymentCycleDetail>> GetCycleDetailsAsync(int cycleId);
}

public class PaymentCycleService : IPaymentCycleService
{
    private readonly SqlConnectionFactory _connectionFactory;

    public PaymentCycleService(SqlConnectionFactory connectionFactory)
    {
        _connectionFactory = connectionFactory;
    }

    public async Task<int> CreatePaymentCycleAsync(DateTime startDate, DateTime endDate)
    {
        using var connection = _connectionFactory.CreateConnection();
        
        var cycleName = $"Cycle_{startDate:yyyyMMdd}_{endDate:yyyyMMdd}";
        
        var cycleId = await connection.QuerySingleAsync<int>(@"
            INSERT INTO payment_cycles (cycle_name, start_date, end_date, status)
            VALUES (@CycleName, @StartDate, @EndDate, 'active')
            RETURNING id",
            new { CycleName = cycleName, StartDate = startDate, EndDate = endDate });

        // Calculate farmer payments for this cycle
        await CalculateFarmerPaymentsAsync(connection, cycleId, startDate, endDate);
        
        return cycleId;
    }

    private async Task CalculateFarmerPaymentsAsync(IDbConnection connection, int cycleId, DateTime startDate, DateTime endDate)
    {
        var farmerPayments = await connection.QueryAsync<dynamic>(@"
            SELECT 
                mc.farmer_id,
                f.name as farmer_name,
                SUM(mc.qty_ltr) as total_qty,
                SUM(mc.due_amt) as total_amount,
                COALESCE(adv.advance_deduction, 0) as advance_deduction
            FROM milk_collection mc
            JOIN farmer f ON mc.farmer_id = f.id
            LEFT JOIN (
                SELECT 
                    fa.farmer_id,
                    LEAST(fa.remaining_amount, fa.installment_amount) as advance_deduction
                FROM farmer_advances fa 
                WHERE fa.status = 'active'
            ) adv ON mc.farmer_id = adv.farmer_id
            WHERE mc.date BETWEEN @StartDate AND @EndDate
            AND mc.payment_status = 'pending'
            GROUP BY mc.farmer_id, f.name, adv.advance_deduction",
            new { StartDate = startDate, EndDate = endDate });

        foreach (var payment in farmerPayments)
        {
            var finalAmount = (decimal)payment.total_amount - (decimal)payment.advance_deduction;
            
            await connection.ExecuteAsync(@"
                INSERT INTO payment_cycle_details 
                (cycle_id, farmer_id, total_milk_qty, total_amount, advance_deduction, final_amount)
                VALUES (@CycleId, @FarmerId, @TotalQty, @TotalAmount, @AdvanceDeduction, @FinalAmount)",
                new {
                    CycleId = cycleId,
                    FarmerId = payment.farmer_id,
                    TotalQty = payment.total_qty,
                    TotalAmount = payment.total_amount,
                    AdvanceDeduction = payment.advance_deduction,
                    FinalAmount = finalAmount
                });
        }

        // Update cycle totals
        await connection.ExecuteAsync(@"
            UPDATE payment_cycles 
            SET total_farmers = (SELECT COUNT(*) FROM payment_cycle_details WHERE cycle_id = @CycleId),
                total_amount = (SELECT SUM(final_amount) FROM payment_cycle_details WHERE cycle_id = @CycleId)
            WHERE id = @CycleId",
            new { CycleId = cycleId });
    }

    public async Task<bool> ProcessPaymentCycleAsync(int cycleId)
    {
        using var connection = _connectionFactory.CreateConnection();
        using var transaction = connection.BeginTransaction();
        
        try
        {
            // Mark milk collections as paid
            await connection.ExecuteAsync(@"
                UPDATE milk_collection 
                SET payment_status = 'paid', cycle_id = @CycleId
                WHERE farmer_id IN (
                    SELECT farmer_id FROM payment_cycle_details WHERE cycle_id = @CycleId
                ) AND payment_status = 'pending'",
                new { CycleId = cycleId }, transaction);

            // Process advance deductions
            await connection.ExecuteAsync(@"
                INSERT INTO advance_deductions (advance_id, cycle_id, deduction_amount, remaining_balance)
                SELECT 
                    fa.id,
                    @CycleId,
                    pcd.advance_deduction,
                    fa.remaining_amount - pcd.advance_deduction
                FROM payment_cycle_details pcd
                JOIN farmer_advances fa ON pcd.farmer_id = fa.farmer_id
                WHERE pcd.cycle_id = @CycleId AND pcd.advance_deduction > 0 AND fa.status = 'active'",
                new { CycleId = cycleId }, transaction);

            // Update advance balances
            await connection.ExecuteAsync(@"
                UPDATE farmer_advances 
                SET remaining_amount = remaining_amount - (
                    SELECT COALESCE(SUM(deduction_amount), 0) 
                    FROM advance_deductions 
                    WHERE advance_id = farmer_advances.id AND cycle_id = @CycleId
                )
                WHERE farmer_id IN (
                    SELECT farmer_id FROM payment_cycle_details WHERE cycle_id = @CycleId
                )",
                new { CycleId = cycleId }, transaction);

            // Mark completed advances
            await connection.ExecuteAsync(@"
                UPDATE farmer_advances 
                SET status = 'completed' 
                WHERE remaining_amount <= 0 AND status = 'active'",
                null, transaction);

            // Update cycle status
            await connection.ExecuteAsync(@"
                UPDATE payment_cycles 
                SET status = 'processing', processed_farmers = total_farmers
                WHERE id = @CycleId",
                new { CycleId = cycleId }, transaction);

            transaction.Commit();
            return true;
        }
        catch
        {
            transaction.Rollback();
            return false;
        }
    }

    public async Task<string> GenerateBankFileAsync(int cycleId, string bankName)
    {
        using var connection = _connectionFactory.CreateConnection();
        
        var paymentDetails = await connection.QueryAsync<dynamic>(@"
            SELECT 
                pcd.farmer_id,
                f.name as farmer_name,
                f.bank_account_number,
                f.bank_ifsc_code,
                pcd.final_amount,
                pcd.transaction_reference
            FROM payment_cycle_details pcd
            JOIN farmer f ON pcd.farmer_id = f.id
            WHERE pcd.cycle_id = @CycleId 
            AND f.bank_account_number IS NOT NULL 
            AND f.bank_ifsc_code IS NOT NULL
            ORDER BY f.name",
            new { CycleId = cycleId });

        var fileName = $"PaymentFile_{bankName}_{cycleId}_{DateTime.Now:yyyyMMddHHmmss}.csv";
        var filePath = Path.Combine("uploads", "bank_files", fileName);
        
        Directory.CreateDirectory(Path.GetDirectoryName(filePath)!);
        
        using var writer = new StreamWriter(filePath);
        
        // CSV Header for most Indian banks
        await writer.WriteLineAsync("Account Number,IFSC Code,Beneficiary Name,Amount,Reference");
        
        foreach (var detail in paymentDetails)
        {
            await writer.WriteLineAsync($"{detail.bank_account_number},{detail.bank_ifsc_code},{detail.farmer_name},{detail.final_amount},DAIRY_PAYMENT_{cycleId}_{detail.farmer_id}");
        }

        // Record bank file generation
        await connection.ExecuteAsync(@"
            INSERT INTO bank_upload_batches (cycle_id, bank_name, file_format, file_path, total_records, total_amount)
            VALUES (@CycleId, @BankName, 'CSV', @FilePath, @TotalRecords, @TotalAmount)",
            new {
                CycleId = cycleId,
                BankName = bankName,
                FilePath = filePath,
                TotalRecords = paymentDetails.Count(),
                TotalAmount = paymentDetails.Sum(d => (decimal)d.final_amount)
            });

        await connection.ExecuteAsync(@"
            UPDATE payment_cycles 
            SET bank_file_generated = true, bank_file_path = @FilePath
            WHERE id = @CycleId",
            new { CycleId = cycleId, FilePath = filePath });

        return filePath;
    }

    public async Task<List<PaymentCycleDetail>> GetCycleDetailsAsync(int cycleId)
    {
        using var connection = _connectionFactory.CreateConnection();
        
        var details = await connection.QueryAsync<PaymentCycleDetail>(@"
            SELECT 
                pcd.*,
                f.name as farmer_name,
                f.code as farmer_code
            FROM payment_cycle_details pcd
            JOIN farmer f ON pcd.farmer_id = f.id
            WHERE pcd.cycle_id = @CycleId
            ORDER BY f.name",
            new { CycleId = cycleId });

        return details.ToList();
    }
}

public class PaymentCycleDetail
{
    public int Id { get; set; }
    public int CycleId { get; set; }
    public int FarmerId { get; set; }
    public string FarmerName { get; set; } = "";
    public string FarmerCode { get; set; } = "";
    public decimal TotalMilkQty { get; set; }
    public decimal TotalAmount { get; set; }
    public decimal AdvanceDeduction { get; set; }
    public decimal BonusAmount { get; set; }
    public decimal FinalAmount { get; set; }
    public string PaymentStatus { get; set; } = "pending";
    public string? PaymentMethod { get; set; }
    public string? TransactionReference { get; set; }
    public bool InvoiceGenerated { get; set; }
    public string? InvoicePath { get; set; }
    public DateTime CreatedAt { get; set; }
    public DateTime? PaidAt { get; set; }
}