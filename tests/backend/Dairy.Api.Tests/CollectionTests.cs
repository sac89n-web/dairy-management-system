using System.Net.Http.Json;
using System.Net;
using FluentAssertions;
using DotNetEnv;

namespace Dairy.Api.Tests;

public class CollectionTests : IDisposable
{
    private readonly HttpClient _httpClient;
    private readonly string _apiBaseUrl;
    private readonly string _apiKey;

    public CollectionTests()
    {
        // Load environment variables
        Env.Load("../../.env.tests");
        
        _apiBaseUrl = Environment.GetEnvironmentVariable("API_BASE_URL") ?? "http://localhost:8081";
        _apiKey = Environment.GetEnvironmentVariable("API_KEY") ?? "";

        _httpClient = new HttpClient();
        _httpClient.BaseAddress = new Uri(_apiBaseUrl);
        
        if (!string.IsNullOrEmpty(_apiKey))
        {
            _httpClient.DefaultRequestHeaders.Authorization = 
                new System.Net.Http.Headers.AuthenticationHeaderValue("Bearer", _apiKey);
        }
    }

    [Fact]
    public async Task CreateCollection_ValidData_ReturnsCreated()
    {
        // Arrange
        var collection = new
        {
            farmerId = 1,
            shiftId = 1,
            date = DateTime.Today.ToString("yyyy-MM-dd"),
            weightKg = 25.5m,
            fat = 4.2m,
            snf = 8.8m,
            rate = 52.50m
        };

        // Act
        var response = await _httpClient.PostAsJsonAsync("/api/collections", collection);

        // Assert
        response.StatusCode.Should().Be(HttpStatusCode.Created);
        
        var result = await response.Content.ReadFromJsonAsync<dynamic>();
        result.Should().NotBeNull();
    }

    [Fact]
    public async Task CreateCollection_InvalidFat_ReturnsBadRequest()
    {
        // Arrange
        var collection = new
        {
            farmerId = 1,
            shiftId = 1,
            date = DateTime.Today.ToString("yyyy-MM-dd"),
            weightKg = 25.5m,
            fat = 16.0m, // Invalid - too high
            snf = 8.8m,
            rate = 52.50m
        };

        // Act
        var response = await _httpClient.PostAsJsonAsync("/api/collections", collection);

        // Assert
        response.StatusCode.Should().Be(HttpStatusCode.BadRequest);
    }

    [Fact]
    public async Task GetCollections_ReturnsOk()
    {
        // Act
        var response = await _httpClient.GetAsync("/api/collections");

        // Assert
        response.StatusCode.Should().Be(HttpStatusCode.OK);
        
        var result = await response.Content.ReadAsStringAsync();
        result.Should().NotBeNullOrEmpty();
    }

    public void Dispose()
    {
        _httpClient?.Dispose();
    }
}