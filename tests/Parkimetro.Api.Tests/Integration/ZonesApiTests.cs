using System.Net;
using System.Net.Http.Json;
using System.Text.Json;

namespace Parkimetro.Api.Tests.Integration;

public class ZonesApiTests : IClassFixture<ApiFactory>
{
    private readonly HttpClient _client;

    public ZonesApiTests(ApiFactory factory)
    {
        _client = factory.CreateClient();
    }

    [Fact]
    public async Task GetZones_ReturnsSeededZones()
    {
        var response = await _client.GetAsync("/api/zones");

        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
        var zones = await response.Content.ReadFromJsonAsync<JsonElement>(HttpClientExtensions.JsonOptions);
        Assert.True(zones.GetArrayLength() >= 2);
    }

    [Fact]
    public async Task GetZone_WhenMissing_ReturnsNotFound()
    {
        var response = await _client.GetAsync($"/api/zones/{Guid.NewGuid()}");
        Assert.Equal(HttpStatusCode.NotFound, response.StatusCode);
    }

    [Fact]
    public async Task CreateZone_WithName_ReturnsCreated()
    {
        var response = await _client.PostAsJsonAsync("/api/zones", new { name = "  Rivera  ", city = "  León  ", videoUrl = " /api/cameras/demo " });
        Assert.Equal(HttpStatusCode.Created, response.StatusCode);

        var zone = await response.Content.ReadFromJsonAsync<JsonElement>(HttpClientExtensions.JsonOptions);
        var id = zone.GetProperty("id").GetGuid();
        Assert.Equal("Rivera", zone.GetProperty("name").GetString());
        Assert.Equal("/api/cameras/demo", zone.GetProperty("videoUrl").GetString());

        var fetched = await _client.GetAsync($"/api/zones/{id}");
        Assert.Equal(HttpStatusCode.OK, fetched.StatusCode);
    }

    [Fact]
    public async Task CreateZone_WithoutName_ReturnsBadRequest()
    {
        var response = await _client.PostAsJsonAsync("/api/zones", new { name = "  ", city = "Ciudad" });
        Assert.Equal(HttpStatusCode.BadRequest, response.StatusCode);
    }

    [Fact]
    public async Task UpdateZone_ChangesNameAndVideoUrl()
    {
        var created = await _client.PostAsJsonAsync("/api/zones", new { name = "Temporal", city = "Ciudad" });
        var zone = await created.Content.ReadFromJsonAsync<JsonElement>(HttpClientExtensions.JsonOptions);
        var id = zone.GetProperty("id").GetGuid();

        var updated = await _client.PutAsJsonAsync($"/api/zones/{id}", new
        {
            name = "  Malecón  ",
            city = "  Lima  ",
            videoUrl = "/api/cameras/demo"
        });
        Assert.Equal(HttpStatusCode.OK, updated.StatusCode);
        var body = await updated.Content.ReadFromJsonAsync<JsonElement>(HttpClientExtensions.JsonOptions);
        Assert.Equal("Malecón", body.GetProperty("name").GetString());
        Assert.Equal("Lima", body.GetProperty("city").GetString());
        Assert.Equal("/api/cameras/demo", body.GetProperty("videoUrl").GetString());

        var missing = await _client.PutAsJsonAsync($"/api/zones/{Guid.NewGuid()}", new { name = "X", city = "Y" });
        Assert.Equal(HttpStatusCode.NotFound, missing.StatusCode);

        var invalid = await _client.PutAsJsonAsync($"/api/zones/{id}", new { name = "  ", city = "Y" });
        Assert.Equal(HttpStatusCode.BadRequest, invalid.StatusCode);
    }
}
