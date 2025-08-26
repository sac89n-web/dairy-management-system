using Dairy.Infrastructure;
using Xunit;
using Moq;
using System.Threading.Tasks;

public class AuditLogRepositoryTests
{
    [Fact]
    public async Task LogAsync_WritesAuditLog()
    {
        var factoryMock = new Mock<Dairy.Infrastructure.SqlConnectionFactory>("Host=localhost;Port=5432;Database=dairy;Username=dairy_app;Password=your_password");
        var repo = new AuditLogRepository(factoryMock.Object);
        // This test would require a real DB or integration test setup
        // For now, just check method signature
        await repo.LogAsync(1, "Create", "Sale", 1, "Created sale record");
    }
}
