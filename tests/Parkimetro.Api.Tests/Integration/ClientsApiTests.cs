using System.Net;
using System.Net.Http.Headers;
using System.Net.Http.Json;
using System.Text.Json;

namespace Parkimetro.Api.Tests.Integration;

public class ClientsApiTests : IClassFixture<ApiFactory>, IAsyncLifetime
{
    private readonly ApiFactory _factory;
    private readonly HttpClient _client;

    public ClientsApiTests(ApiFactory factory)
    {
        _factory = factory;
        _client = factory.CreateClient();
    }

    public Task InitializeAsync() => _client.LoginAsAnaAsync();

    public Task DisposeAsync() => Task.CompletedTask;

    [Fact]
    public async Task GetClient_RequiresOperator()
    {
        var anonymous = _factory.CreateClient();
        var response = await anonymous.GetAsync("/api/clients/12345678");
        Assert.Equal(HttpStatusCode.Unauthorized, response.StatusCode);
    }

    [Fact]
    public async Task GetClient_ValidatesAndResolvesDni()
    {
        var invalid = await _client.GetAsync("/api/clients/123");
        Assert.Equal(HttpStatusCode.BadRequest, invalid.StatusCode);

        var missing = await _client.GetAsync("/api/clients/00000000");
        Assert.Equal(HttpStatusCode.NotFound, missing.StatusCode);

        var found = await _client.GetFromJsonAsync<JsonElement>("/api/clients/12345678", HttpClientExtensions.JsonOptions);
        Assert.Equal("PEREZ PEREZ JUAN", found.GetProperty("name").GetString());
        Assert.Equal("10123456780", found.GetProperty("ruc").GetString());
    }
}
