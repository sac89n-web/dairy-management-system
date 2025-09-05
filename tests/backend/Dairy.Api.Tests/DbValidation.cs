using Npgsql;
using Dapper;
using FluentAssertions;
using DotNetEnv;
using System.Net.Http.Json;

namespace Dairy.Api.Tests;

public class DbValidation : IDisposable
{
    private readonly HttpClient _httpClient;
    private readonly string _connectionString;
    private readonly string _apiBaseUrl;

    public DbValidation()
    {
        // Load environment variables
        Env.Load("../../.env.tests");
        
        _connectionString = Environment.GetEnvironmentVariable("DB_CONN") ?? 
            "Host=localhost;Database=postgres;Username=admin;Password=admin123;SearchPath=dairy";
        _apiBaseUrl = Environment.GetEnvironmentVariable("API_BASE_URL") ?? "http://localhost:8081";

        _httpClient = new HttpClient();
        _httpClient.BaseAddress = new Uri(_apiBaseUrl);
    }

    [Fact]
    public async Task CreateCollection_ValidatesInDatabase()
    {
        // Arrange
        var collection = new
        {
            farmerId = 1,
            shiftId = 1,
            date = DateTime.Today.ToString("yyyy-MM-dd"),
            weightKg = 30.0m,
            fat = 4.5m,
            snf = 9.0m,
            rate = 55.00m
        };

        // Act - Create collection via API
        var response = await _httpClient.PostAsJsonAsync("/api/collections", collection);
        response.EnsureSuccessStatusCode();
        
        var result = await response.Content.ReadFromJsonAsync<dynamic>();
        var collectionId = (int)result.GetProperty("id").GetInt32();

        // Assert - Verify in database
        using var connection = new NpgsqlConnection(_connectionString);
        await connection.OpenAsync();

        var dbCollection = await connection.QuerySingleOrDefaultAsync(@"
            SELECT id, farmer_id, shift_id, date, qty_ltr, fat_pct, snf_pct, price_per_ltr, due_amt
            FROM milk_collection 
            WHERE id = @Id", new { Id = collectionId });

        dbCollection.Should().NotBeNull();
        ((int)dbCollection.farmer_id).Should().Be(collection.farmerId);
        ((decimal)dbCollection.qty_ltr).Should().Be(collection.weightKg);
        ((decimal)dbCollection.fat_pct).Should().Be(collection.fat);
        ((decimal)dbCollection.snf_pct).Should().Be(collection.snf);

        // Cleanup
        await connection.ExecuteAsync("DELETE FROM milk_collection WHERE id = @Id", new { Id = collectionId });
    }

    [Fact]
    public async Task DatabaseConnection_IsValid()
    {
        // Act & Assert
        using var connection = new NpgsqlConnection(_connectionString);
        await connection.OpenAsync();

        var result = await connection.QuerySingleAsync<string>("SELECT version()");
        result.Should().Contain("PostgreSQL");
    }

    [Fact]
    public async Task RequiredTables_Exist()
    {
        // Act
        using var connection = new NpgsqlConnection(_connectionString);
        await connection.OpenAsync();

        var tables = await connection.QueryAsync<string>(@"
            SELECT table_name 
            FROM information_schema.tables 
            WHERE table_schema = 'dairy' 
            AND table_name IN ('farmer', 'milk_collection', 'payment_cycles', 'bonus_configurations')");

        // Assert
        var tableList = tables.ToList();
        tableList.Should().Contain("farmer");
        tableList.Should().Contain("milk_collection");
        tableList.Should().Contain("payment_cycles");
        tableList.Should().Contain("bonus_configurations");
    }

    public void Dispose()
    {
        _httpClient?.Dispose();
    }
}