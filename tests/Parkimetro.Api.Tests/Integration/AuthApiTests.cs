using System.Net;
using System.Net.Http.Json;
using System.Text.Json;

namespace Parkimetro.Api.Tests.Integration;

public class AuthApiTests : IClassFixture<ApiFactory>
{
    private readonly HttpClient _client;

    public AuthApiTests(ApiFactory factory)
    {
        _client = factory.CreateClient();
    }

    [Fact]
    public async Task Login_WithValidCredentials_ReturnsToken()
    {
        var response = await _client.PostAsJsonAsync("/api/auth/login", new { username = "ana", pin = "1234" });

        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
        var json = await response.Content.ReadFromJsonAsync<JsonElement>(HttpClientExtensions.JsonOptions);
        Assert.False(string.IsNullOrWhiteSpace(json.GetProperty("token").GetString()));
        Assert.Equal("Ana López", json.GetProperty("operator").GetProperty("name").GetString());
    }

    [Fact]
    public async Task Login_WithInvalidPin_ReturnsUnauthorized()
    {
        var response = await _client.PostAsJsonAsync("/api/auth/login", new { username = "ana", pin = "0000" });
        Assert.Equal(HttpStatusCode.Unauthorized, response.StatusCode);
    }
}
