using System.Net;
using System.Net.Http.Json;
using System.Text.Json;

namespace Parkimetro.Api.Tests.Integration;

public class SpacesApiTests : IClassFixture<ApiFactory>
{
    private static readonly Guid CentroId = Guid.Parse("11111111-1111-1111-1111-111111111111");
    private readonly HttpClient _client;

    public SpacesApiTests(ApiFactory factory)
    {
        _client = factory.CreateClient();
    }

    [Fact]
    public async Task GetSpaces_CanFilterByZoneAndStatus()
    {
        var all = await _client.GetFromJsonAsync<JsonElement>("/api/spaces", HttpClientExtensions.JsonOptions);
        var free = await _client.GetFromJsonAsync<JsonElement>("/api/spaces?status=free", HttpClientExtensions.JsonOptions);
        var centro = await _client.GetFromJsonAsync<JsonElement>($"/api/spaces?zoneId={CentroId}", HttpClientExtensions.JsonOptions);

        Assert.True(all.GetArrayLength() >= 6);
        Assert.True(free.GetArrayLength() >= 3);
        Assert.True(centro.GetArrayLength() >= 3);
    }

    [Fact]
    public async Task GetSpace_WhenMissing_ReturnsNotFound()
    {
        var response = await _client.GetAsync($"/api/spaces/{Guid.NewGuid()}");
        Assert.Equal(HttpStatusCode.NotFound, response.StatusCode);
    }

    [Fact]
    public async Task CreateSpace_ValidatesAndPersists()
    {
        var missingZone = await _client.PostAsJsonAsync("/api/spaces", new
        {
            code = "Z-01",
            zoneId = Guid.NewGuid(),
            latitude = 1,
            longitude = 1,
            hourlyRate = 10
        });
        Assert.Equal(HttpStatusCode.BadRequest, missingZone.StatusCode);

        var emptyCode = await _client.PostAsJsonAsync("/api/spaces", new
        {
            code = " ",
            zoneId = CentroId,
            latitude = 1,
            longitude = 1,
            hourlyRate = 10
        });
        Assert.Equal(HttpStatusCode.BadRequest, emptyCode.StatusCode);

        var created = await _client.PostAsJsonAsync("/api/spaces", new
        {
            code = " A-99 ",
            zoneId = CentroId,
            latitude = 19.43,
            longitude = -99.13,
            hourlyRate = 20,
            notes = "esquina"
        });
        Assert.Equal(HttpStatusCode.Created, created.StatusCode);
        var space = await created.Content.ReadFromJsonAsync<JsonElement>(HttpClientExtensions.JsonOptions);
        Assert.Equal("A-99", space.GetProperty("code").GetString());
        Assert.Equal("free", space.GetProperty("status").GetString());

        var duplicate = await _client.PostAsJsonAsync("/api/spaces", new
        {
            code = "A-99",
            zoneId = CentroId,
            latitude = 19.43,
            longitude = -99.13,
            hourlyRate = 20
        });
        Assert.Equal(HttpStatusCode.Conflict, duplicate.StatusCode);
    }

    [Fact]
    public async Task UpdateAndChangeStatus_RoundTrips()
    {
        var created = await _client.PostAsJsonAsync("/api/spaces", new
        {
            code = "C-10",
            zoneId = CentroId,
            latitude = 19.4,
            longitude = -99.1,
            hourlyRate = 15
        });
        var space = await created.Content.ReadFromJsonAsync<JsonElement>(HttpClientExtensions.JsonOptions);
        var id = space.GetProperty("id").GetGuid();

        var updated = await _client.PutAsJsonAsync($"/api/spaces/{id}", new
        {
            code = "C-11",
            latitude = 19.5,
            longitude = -99.2,
            hourlyRate = 22,
            notes = "actualizado"
        });
        Assert.Equal(HttpStatusCode.OK, updated.StatusCode);

        var reserved = await _client.PatchAsJsonAsync($"/api/spaces/{id}/status", new { status = "reserved", dni = "12345678" });
        Assert.Equal(HttpStatusCode.OK, reserved.StatusCode);
        var reservedBody = await reserved.Content.ReadFromJsonAsync<JsonElement>(HttpClientExtensions.JsonOptions);
        Assert.Equal("reserved", reservedBody.GetProperty("status").GetString());
        Assert.Equal("12345678", reservedBody.GetProperty("clientDni").GetString());
        Assert.Equal("PEREZ PEREZ JUAN", reservedBody.GetProperty("clientName").GetString());

        var missing = await _client.PutAsJsonAsync($"/api/spaces/{Guid.NewGuid()}", new
        {
            code = "X",
            latitude = 1,
            longitude = 1,
            hourlyRate = 1,
            notes = (string?)null
        });
        Assert.Equal(HttpStatusCode.NotFound, missing.StatusCode);
    }

    [Fact]
    public async Task ReserveSpace_RequiresKnownDni()
    {
        var created = await _client.PostAsJsonAsync("/api/spaces", new
        {
            code = "R-01",
            zoneId = CentroId,
            latitude = 19.4,
            longitude = -99.1,
            hourlyRate = 10
        });
        var space = await created.Content.ReadFromJsonAsync<JsonElement>(HttpClientExtensions.JsonOptions);
        var id = space.GetProperty("id").GetGuid();

        var withoutDni = await _client.PostAsJsonAsync($"/api/spaces/{id}/reserve", new { dni = "123" });
        Assert.Equal(HttpStatusCode.BadRequest, withoutDni.StatusCode);

        var unknown = await _client.PostAsJsonAsync($"/api/spaces/{id}/reserve", new { dni = "00000000" });
        Assert.Equal(HttpStatusCode.NotFound, unknown.StatusCode);

        var reserved = await _client.PostAsJsonAsync($"/api/spaces/{id}/reserve", new { dni = "12345678" });
        Assert.Equal(HttpStatusCode.OK, reserved.StatusCode);
        var body = await reserved.Content.ReadFromJsonAsync<JsonElement>(HttpClientExtensions.JsonOptions);
        Assert.Equal("reserved", body.GetProperty("status").GetString());
        Assert.Equal("PEREZ PEREZ JUAN", body.GetProperty("clientName").GetString());

        var freed = await _client.PatchAsJsonAsync($"/api/spaces/{id}/status", new { status = "free" });
        var freeBody = await freed.Content.ReadFromJsonAsync<JsonElement>(HttpClientExtensions.JsonOptions);
        Assert.Equal(JsonValueKind.Null, freeBody.GetProperty("clientName").ValueKind);
    }

    [Fact]
    public async Task ReserveSpace_WhenMissing_ReturnsNotFound()
    {
        var response = await _client.PostAsJsonAsync($"/api/spaces/{Guid.NewGuid()}/reserve", new { dni = "12345678" });
        Assert.Equal(HttpStatusCode.NotFound, response.StatusCode);
    }

    [Fact]
    public async Task ReserveSpace_WhenOutOfService_ReturnsBadRequest()
    {
        var spaces = await _client.GetFromJsonAsync<JsonElement>("/api/spaces?status=outOfService", HttpClientExtensions.JsonOptions);
        var id = spaces[0].GetProperty("id").GetGuid();
        var response = await _client.PostAsJsonAsync($"/api/spaces/{id}/reserve", new { dni = "12345678" });
        Assert.Equal(HttpStatusCode.BadRequest, response.StatusCode);
    }

    [Fact]
    public async Task DeleteSpace_RemovesTheSpace()
    {
        var created = await _client.PostAsJsonAsync("/api/spaces", new
        {
            code = "D-01",
            zoneId = CentroId,
            latitude = 19.4,
            longitude = -99.1,
            hourlyRate = 10
        });
        var space = await created.Content.ReadFromJsonAsync<JsonElement>(HttpClientExtensions.JsonOptions);
        var id = space.GetProperty("id").GetGuid();

        var deleted = await _client.DeleteAsync($"/api/spaces/{id}");
        Assert.Equal(HttpStatusCode.NoContent, deleted.StatusCode);

        var missing = await _client.GetAsync($"/api/spaces/{id}");
        Assert.Equal(HttpStatusCode.NotFound, missing.StatusCode);
    }
}
