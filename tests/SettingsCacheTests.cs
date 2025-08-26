using Dairy.Application;
using Xunit;
using Moq;
using Microsoft.Extensions.Caching.Memory;
using Microsoft.Extensions.Configuration;
using System.Threading.Tasks;

public class SettingsCacheTests
{
    [Fact]
    public async Task GetSettingsAsync_ReturnsSettings()
    {
        var cache = new MemoryCache(new MemoryCacheOptions());
        var configMock = new Mock<IConfiguration>();
        configMock.Setup(c => c.GetConnectionString("Postgres")).Returns("Host=localhost;Port=5432;Database=dairy;Username=dairy_app;Password=your_password");
        var settingsCache = new SettingsCache(cache, configMock.Object);
        var settings = await settingsCache.GetSettingsAsync();
        Assert.NotNull(settings);
    }
}
