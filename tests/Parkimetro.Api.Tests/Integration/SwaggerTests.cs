using System.Net;

namespace Parkimetro.Api.Tests.Integration;

public class SwaggerTests : IClassFixture<ApiFactory>
{
    private readonly HttpClient _client;

    public SwaggerTests(ApiFactory factory)
    {
        _client = factory.CreateClient();
    }

    [Fact]
    public async Task SwaggerUi_IsAvailable()
    {
        var response = await _client.GetAsync("/swagger/index.html");
        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
    }

    [Fact]
    public async Task OpenApiDocument_DescribesParkimetroApi()
    {
        var response = await _client.GetAsync("/openapi/v1.json");
        Assert.Equal(HttpStatusCode.OK, response.StatusCode);

        var json = await response.Content.ReadAsStringAsync();
        Assert.Contains("Parkímetro API", json, StringComparison.Ordinal);
        Assert.Contains("/api/cameras", json, StringComparison.Ordinal);
        Assert.Contains("/api/clients", json, StringComparison.Ordinal);
        Assert.Contains("/api/zones", json, StringComparison.Ordinal);
        Assert.Contains("/api/spaces", json, StringComparison.Ordinal);
        Assert.Contains("/api/sessions", json, StringComparison.Ordinal);
        Assert.Contains("/api/auth/login", json, StringComparison.Ordinal);
    }
}

public class ProductionSwaggerTests : IClassFixture<ProductionApiFactory>
{
    private readonly HttpClient _client;

    public ProductionSwaggerTests(ProductionApiFactory factory)
    {
        _client = factory.CreateClient();
    }

    [Fact]
    public async Task SwaggerUi_IsDisabledInProduction()
    {
        var response = await _client.GetAsync("/swagger/index.html");
        Assert.Equal(HttpStatusCode.NotFound, response.StatusCode);
    }

    [Fact]
    public async Task OpenApiDocument_IsDisabledInProduction()
    {
        var response = await _client.GetAsync("/openapi/v1.json");
        Assert.Equal(HttpStatusCode.NotFound, response.StatusCode);
    }
}
