using System.Net;
using System.Net.Http.Json;
using System.Text.Json;

namespace Parkimetro.Api.Tests.Integration;

public class OperatorsApiTests : IClassFixture<ApiFactory>, IAsyncLifetime
{
    private readonly HttpClient _client;

    public OperatorsApiTests(ApiFactory factory)
    {
        _client = factory.CreateClient();
    }

    public Task InitializeAsync() => _client.LoginAsAnaAsync();

    public Task DisposeAsync() => Task.CompletedTask;

    [Fact]
    public async Task GetOperators_ReturnsSeededAna()
    {
        var operators = await _client.GetFromJsonAsync<JsonElement>("/api/operators", HttpClientExtensions.JsonOptions);
        Assert.True(operators.GetArrayLength() >= 1);
        Assert.Contains(
            operators.EnumerateArray(),
            item => item.GetProperty("username").GetString() == "ana");
    }

    [Fact]
    public async Task CreateUpdateAndDelete_RoundTrips()
    {
        var created = await _client.PostAsJsonAsync("/api/operators", new
        {
            name = "  Luis Mora  ",
            username = "  Luis  ",
            pin = "5678"
        });
        Assert.Equal(HttpStatusCode.Created, created.StatusCode);
        var body = await created.Content.ReadFromJsonAsync<JsonElement>(HttpClientExtensions.JsonOptions);
        var id = body.GetProperty("id").GetGuid();
        Assert.Equal("Luis Mora", body.GetProperty("name").GetString());
        Assert.Equal("luis", body.GetProperty("username").GetString());

        var updated = await _client.PutAsJsonAsync($"/api/operators/{id}", new
        {
            name = "Luis M.",
            username = "luism",
            pin = (string?)null
        });
        Assert.Equal(HttpStatusCode.OK, updated.StatusCode);

        var login = await _client.PostAsJsonAsync("/api/auth/login", new { username = "luism", pin = "5678" });
        Assert.Equal(HttpStatusCode.OK, login.StatusCode);

        var deleted = await _client.DeleteAsync($"/api/operators/{id}");
        Assert.Equal(HttpStatusCode.NoContent, deleted.StatusCode);
    }

    [Fact]
    public async Task CreateOperator_ValidatesInput()
    {
        var missingName = await _client.PostAsJsonAsync("/api/operators", new
        {
            name = " ",
            username = "leo",
            pin = "1234"
        });
        Assert.Equal(HttpStatusCode.BadRequest, missingName.StatusCode);

        var shortPin = await _client.PostAsJsonAsync("/api/operators", new
        {
            name = "Leo",
            username = "leo",
            pin = "12"
        });
        Assert.Equal(HttpStatusCode.BadRequest, shortPin.StatusCode);

        var duplicate = await _client.PostAsJsonAsync("/api/operators", new
        {
            name = "Ana 2",
            username = "ana",
            pin = "9999"
        });
        Assert.Equal(HttpStatusCode.Conflict, duplicate.StatusCode);
    }

    [Fact]
    public async Task DeleteLastOperator_ReturnsBadRequest()
    {
        var operators = await _client.GetFromJsonAsync<JsonElement>("/api/operators", HttpClientExtensions.JsonOptions);
        foreach (var item in operators.EnumerateArray())
        {
            var username = item.GetProperty("username").GetString();
            if (username is "ana")
            {
                continue;
            }

            await _client.DeleteAsync($"/api/operators/{item.GetProperty("id").GetGuid()}");
        }

        var ana = operators.EnumerateArray().First(item => item.GetProperty("username").GetString() == "ana");
        var response = await _client.DeleteAsync($"/api/operators/{ana.GetProperty("id").GetGuid()}");
        Assert.Equal(HttpStatusCode.BadRequest, response.StatusCode);
    }
}
