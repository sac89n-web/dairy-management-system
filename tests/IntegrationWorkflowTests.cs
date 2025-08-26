using Xunit;
using Dairy.Infrastructure;
using Dairy.Domain;
using System.Threading.Tasks;

public class IntegrationWorkflowTests
{
    [Fact]
    public async Task AddSale_AndLogAudit()
    {
        var factory = new SqlConnectionFactory("Host=localhost;Port=5432;Database=dairy;Username=dairy_app;Password=your_password");
        var saleRepo = new SaleRepository(factory);
        var auditRepo = new AuditLogRepository(factory);
        var sale = new Sale { CustomerId = 1, ShiftId = 1, Date = "2025-08-18", QtyLtr = 10, UnitPrice = 50, Discount = 0, PaidAmt = 10, DueAmt = 10, CreatedBy = 1 };
        var saleId = await saleRepo.AddAsync(sale);
        await auditRepo.LogAsync(1, "Create", "Sale", saleId, "Created sale record");
        Assert.True(saleId > 0);
    }
}
