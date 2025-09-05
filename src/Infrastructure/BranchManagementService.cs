using Dapper;
using Npgsql;

namespace Dairy.Infrastructure;

public class BranchManagementService : IBranchManagementService
{
    private readonly SqlConnectionFactory _connectionFactory;

    public BranchManagementService(SqlConnectionFactory connectionFactory)
    {
        _connectionFactory = connectionFactory;
    }

    public async Task<List<Branch>> GetBranchHierarchyAsync()
    {
        using var connection = (NpgsqlConnection)_connectionFactory.CreateConnection();
        await connection.OpenAsync();

        try
        {
            var branches = (await connection.QueryAsync<Branch>(@"
                SELECT id, branch_code, branch_name, parent_branch_id, branch_type, 
                       address, contact_person, phone, email, is_active
                FROM dairy.branches 
                WHERE is_active = true
                ORDER BY branch_type, branch_name")).ToList();

            // Get stats for each branch
            foreach (var branch in branches)
            {
                branch.Stats = await GetBranchStatsAsync(connection, branch.Id);
            }

            // Build hierarchy
            var rootBranches = branches.Where(b => b.ParentBranchId == null).ToList();
            foreach (var root in rootBranches)
            {
                BuildBranchHierarchy(root, branches);
            }

            return rootBranches;
        }
        catch
        {
            return new List<Branch>();
        }
    }

    public async Task<Branch> GetBranchAsync(int branchId)
    {
        using var connection = (NpgsqlConnection)_connectionFactory.CreateConnection();
        await connection.OpenAsync();

        try
        {
            var branch = await connection.QuerySingleOrDefaultAsync<Branch>(@"
                SELECT id, branch_code, branch_name, parent_branch_id, branch_type, 
                       address, contact_person, phone, email, is_active
                FROM dairy.branches 
                WHERE id = @branchId",
                new { branchId });

            if (branch != null)
            {
                branch.Stats = await GetBranchStatsAsync(connection, branchId);
            }

            return branch ?? new Branch();
        }
        catch
        {
            return new Branch();
        }
    }

    public async Task<List<InterBranchTransfer>> GetTransfersAsync(int? branchId = null)
    {
        using var connection = (NpgsqlConnection)_connectionFactory.CreateConnection();
        await connection.OpenAsync();

        try
        {
            var whereClause = branchId.HasValue ? 
                "WHERE (from_branch_id = @branchId OR to_branch_id = @branchId)" : "";

            return (await connection.QueryAsync<InterBranchTransfer>($@"
                SELECT t.*, 
                       fb.branch_name as FromBranchName,
                       tb.branch_name as ToBranchName
                FROM dairy.inter_branch_transfers t
                JOIN dairy.branches fb ON t.from_branch_id = fb.id
                JOIN dairy.branches tb ON t.to_branch_id = tb.id
                {whereClause}
                ORDER BY t.created_at DESC
                LIMIT 100",
                new { branchId })).ToList();
        }
        catch
        {
            return new List<InterBranchTransfer>();
        }
    }

    public async Task<InterBranchTransfer> CreateTransferAsync(CreateTransferRequest request)
    {
        using var connection = (NpgsqlConnection)_connectionFactory.CreateConnection();
        await connection.OpenAsync();

        try
        {
            var transferNumber = $"TRF{DateTime.Now:yyyyMMdd}{new Random().Next(1000, 9999)}";

            var transferId = await connection.QuerySingleAsync<int>(@"
                INSERT INTO dairy.inter_branch_transfers 
                (transfer_number, from_branch_id, to_branch_id, transfer_type, 
                 quantity, amount, transfer_date, notes, created_by)
                VALUES (@transferNumber, @fromBranchId, @toBranchId, @transferType,
                        @quantity, @amount, @transferDate, @notes, @createdBy)
                RETURNING id",
                new
                {
                    transferNumber,
                    fromBranchId = request.FromBranchId,
                    toBranchId = request.ToBranchId,
                    transferType = request.TransferType,
                    quantity = request.Quantity,
                    amount = request.Amount,
                    transferDate = request.TransferDate,
                    notes = request.Notes,
                    createdBy = request.CreatedBy
                });

            return await connection.QuerySingleAsync<InterBranchTransfer>(@"
                SELECT t.*, 
                       fb.branch_name as FromBranchName,
                       tb.branch_name as ToBranchName
                FROM dairy.inter_branch_transfers t
                JOIN dairy.branches fb ON t.from_branch_id = fb.id
                JOIN dairy.branches tb ON t.to_branch_id = tb.id
                WHERE t.id = @transferId",
                new { transferId });
        }
        catch (Exception ex)
        {
            throw new Exception($"Failed to create transfer: {ex.Message}");
        }
    }

    public async Task<bool> ApproveTransferAsync(int transferId, int approvedBy)
    {
        using var connection = (NpgsqlConnection)_connectionFactory.CreateConnection();
        await connection.OpenAsync();

        try
        {
            var rowsAffected = await connection.ExecuteAsync(@"
                UPDATE dairy.inter_branch_transfers 
                SET status = 'approved', received_date = CURRENT_DATE
                WHERE id = @transferId AND status = 'pending'",
                new { transferId });

            return rowsAffected > 0;
        }
        catch
        {
            return false;
        }
    }

    public async Task<ConsolidatedReport> GetConsolidatedReportAsync(DateTime fromDate, DateTime toDate)
    {
        using var connection = (NpgsqlConnection)_connectionFactory.CreateConnection();
        await connection.OpenAsync();

        var report = new ConsolidatedReport
        {
            FromDate = fromDate,
            ToDate = toDate
        };

        try
        {
            // Get overall totals
            var totals = await connection.QuerySingleOrDefaultAsync(@"
                SELECT 
                    COALESCE(SUM(mc.qty_ltr), 0) as TotalCollection,
                    COALESCE(SUM(mc.due_amt), 0) as TotalRevenue,
                    COUNT(DISTINCT mc.farmer_id) as TotalFarmers
                FROM dairy.milk_collection mc
                WHERE mc.date BETWEEN @fromDate AND @toDate",
                new { fromDate, toDate });

            if (totals != null)
            {
                report.TotalCollection = totals.TotalCollection;
                report.TotalRevenue = totals.TotalRevenue;
                report.TotalFarmers = totals.TotalFarmers;
            }

            // Get branch summaries
            report.BranchSummaries = (await connection.QueryAsync<BranchSummary>(@"
                SELECT 
                    b.branch_name as BranchName,
                    COALESCE(SUM(mc.qty_ltr), 0) as Collection,
                    COALESCE(SUM(mc.due_amt), 0) as Revenue,
                    COUNT(DISTINCT mc.farmer_id) as FarmerCount,
                    COALESCE(AVG(mc.fat_pct), 0) as AverageQuality
                FROM dairy.branches b
                LEFT JOIN dairy.milk_collection mc ON b.id = mc.branch_id 
                    AND mc.date BETWEEN @fromDate AND @toDate
                WHERE b.is_active = true
                GROUP BY b.id, b.branch_name
                ORDER BY Collection DESC",
                new { fromDate, toDate })).ToList();

            // Get transfer summaries
            report.TransferSummaries = (await connection.QueryAsync<TransferSummary>(@"
                SELECT 
                    transfer_type as TransferType,
                    COUNT(*) as TransferCount,
                    COALESCE(SUM(amount), 0) as TotalAmount,
                    COALESCE(SUM(quantity), 0) as TotalQuantity
                FROM dairy.inter_branch_transfers
                WHERE transfer_date BETWEEN @fromDate AND @toDate
                GROUP BY transfer_type
                ORDER BY TransferCount DESC",
                new { fromDate, toDate })).ToList();
        }
        catch (Exception ex)
        {
            Console.WriteLine($"Consolidated report error: {ex.Message}");
        }

        return report;
    }

    private async Task<BranchStats> GetBranchStatsAsync(NpgsqlConnection connection, int branchId)
    {
        try
        {
            return await connection.QuerySingleOrDefaultAsync<BranchStats>(@"
                SELECT 
                    (SELECT COUNT(*) FROM dairy.farmer WHERE branch_id = @branchId) as FarmerCount,
                    (SELECT COUNT(*) FROM dairy.customer WHERE branch_id = @branchId) as CustomerCount,
                    (SELECT COALESCE(SUM(qty_ltr), 0) FROM dairy.milk_collection 
                     WHERE branch_id = @branchId AND date = CURRENT_DATE) as TodayCollection,
                    (SELECT COALESCE(SUM(due_amt), 0) FROM dairy.milk_collection 
                     WHERE branch_id = @branchId AND date >= DATE_TRUNC('month', CURRENT_DATE)) as MonthlyRevenue,
                    (SELECT COUNT(*) FROM dairy.users WHERE branch_id = @branchId AND is_active = true) as ActiveUsers",
                new { branchId }) ?? new BranchStats();
        }
        catch
        {
            return new BranchStats();
        }
    }

    private void BuildBranchHierarchy(Branch parent, List<Branch> allBranches)
    {
        parent.SubBranches = allBranches.Where(b => b.ParentBranchId == parent.Id).ToList();
        foreach (var child in parent.SubBranches)
        {
            BuildBranchHierarchy(child, allBranches);
        }
    }
}