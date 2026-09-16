using System.Net;
using System.Net.Http.Json;
using System.Text.Json;

namespace Parkimetro.Api.Tests.Integration;

public class SessionsApiTests : IClassFixture<ApiFactory>, IAsyncLifetime
{
    private static readonly Guid CentroId = Guid.Parse("11111111-1111-1111-1111-111111111111");
    private readonly ApiFactory _factory;
    private readonly HttpClient _client;

    public SessionsApiTests(ApiFactory factory)
    {
        _factory = factory;
        _client = factory.CreateClient();
    }

    public Task InitializeAsync() => _client.LoginAsAnaAsync();

    public Task DisposeAsync() => Task.CompletedTask;

    [Fact]
    public async Task StartSession_RequiresOperator()
    {
        var anonymous = _factory.CreateClient();
        var response = await anonymous.PostAsJsonAsync("/api/sessions", new { spaceId = Guid.NewGuid() });
        Assert.Equal(HttpStatusCode.Unauthorized, response.StatusCode);
    }

    [Fact]
    public async Task SessionLifecycle_OccupiesAndReleasesSpace()
    {
        var spaceId = await CreateSpaceAsync("S-01");

        var started = await _client.PostAsJsonAsync(
            "/api/sessions",
            HttpClientExtensions.OccupyPayload(spaceId, "12345678", licensePlate: " abc123 "));
        Assert.Equal(HttpStatusCode.Created, started.StatusCode);
        var session = await started.Content.ReadFromJsonAsync<JsonElement>(HttpClientExtensions.JsonOptions);
        Assert.Equal("ABC123", session.GetProperty("licensePlate").GetString());
        Assert.True(session.GetProperty("isActive").GetBoolean());
        Assert.Equal(1, session.GetProperty("billedHours").GetInt32());
        Assert.Equal(2, session.GetProperty("amount").GetDecimal());
        Assert.NotEqual(JsonValueKind.Null, session.GetProperty("limitUntil").ValueKind);

        var space = await _client.GetFromJsonAsync<JsonElement>($"/api/spaces/{spaceId}", HttpClientExtensions.JsonOptions);
        Assert.Equal("occupied", space.GetProperty("status").GetString());
        Assert.Equal("12345678", space.GetProperty("clientDni").GetString());
        Assert.Equal("PEREZ PEREZ JUAN", space.GetProperty("clientName").GetString());
        Assert.NotEqual(JsonValueKind.Null, space.GetProperty("occupiedSince").ValueKind);
        Assert.NotEqual(JsonValueKind.Null, space.GetProperty("limitUntil").ValueKind);

        var conflict = await _client.PostAsJsonAsync("/api/sessions", new { spaceId });
        Assert.Equal(HttpStatusCode.Conflict, conflict.StatusCode);

        var active = await _client.GetFromJsonAsync<JsonElement>("/api/sessions?activeOnly=true", HttpClientExtensions.JsonOptions);
        Assert.True(active.GetArrayLength() >= 1);

        var sessionId = session.GetProperty("id").GetGuid();
        var ended = await _client.PostAsync($"/api/sessions/{sessionId}/end", null);
        Assert.Equal(HttpStatusCode.OK, ended.StatusCode);
        var endedBody = await ended.Content.ReadFromJsonAsync<JsonElement>(HttpClientExtensions.JsonOptions);
        Assert.Equal(1, endedBody.GetProperty("billedHours").GetInt32());
        Assert.Equal(2, endedBody.GetProperty("amount").GetDecimal());
        Assert.True(endedBody.GetProperty("paid").GetBoolean());

        var released = await _client.GetFromJsonAsync<JsonElement>($"/api/spaces/{spaceId}", HttpClientExtensions.JsonOptions);
        Assert.Equal("free", released.GetProperty("status").GetString());

        var alreadyEnded = await _client.PostAsync($"/api/sessions/{sessionId}/end", null);
        Assert.Equal(HttpStatusCode.BadRequest, alreadyEnded.StatusCode);
    }

    [Fact]
    public async Task StartSession_RequiresClientDataAndLimit()
    {
        var spaceId = await CreateSpaceAsync("S-03");
        var missing = await _client.PostAsJsonAsync("/api/sessions", new { spaceId, licensePlate = "ABC123" });
        Assert.Equal(HttpStatusCode.BadRequest, missing.StatusCode);

        var reserved = await _client.PostAsJsonAsync(
            $"/api/spaces/{spaceId}/reserve",
            HttpClientExtensions.ReservePayload("12345678"));
        reserved.EnsureSuccessStatusCode();

        var wrongDni = await _client.PostAsJsonAsync(
            "/api/sessions",
            HttpClientExtensions.OccupyPayload(spaceId, "87654321"));
        Assert.Equal(HttpStatusCode.Conflict, wrongDni.StatusCode);

        var claimed = await _client.PostAsJsonAsync(
            "/api/sessions",
            HttpClientExtensions.OccupyPayload(spaceId, "12345678", licensePlate: "XYZ99"));
        Assert.Equal(HttpStatusCode.Created, claimed.StatusCode);
        var space = await _client.GetFromJsonAsync<JsonElement>($"/api/spaces/{spaceId}", HttpClientExtensions.JsonOptions);
        Assert.Equal("occupied", space.GetProperty("status").GetString());
        Assert.Equal("XYZ99", space.GetProperty("licensePlate").GetString());
    }

    [Fact]
    public async Task StartSession_WhenSpaceMissingOrOutOfService_Fails()
    {
        var missing = await _client.PostAsJsonAsync("/api/sessions", new { spaceId = Guid.NewGuid() });
        Assert.Equal(HttpStatusCode.NotFound, missing.StatusCode);

        var spaces = await _client.GetFromJsonAsync<JsonElement>("/api/spaces?status=outOfService", HttpClientExtensions.JsonOptions);
        var outOfServiceId = spaces[0].GetProperty("id").GetGuid();
        var blocked = await _client.PostAsJsonAsync("/api/sessions", new { spaceId = outOfServiceId });
        Assert.Equal(HttpStatusCode.BadRequest, blocked.StatusCode);
    }

    [Fact]
    public async Task ChangeStatusToFree_ClosesActiveSession()
    {
        var spaceId = await CreateSpaceAsync("S-02");
        var started = await _client.PostAsJsonAsync(
            "/api/sessions",
            HttpClientExtensions.OccupyPayload(spaceId, "12345678"));
        started.EnsureSuccessStatusCode();
        var session = await started.Content.ReadFromJsonAsync<JsonElement>(HttpClientExtensions.JsonOptions);

        var freed = await _client.PatchAsJsonAsync($"/api/spaces/{spaceId}/status", new { status = "free" });
        Assert.Equal(HttpStatusCode.OK, freed.StatusCode);

        var closed = await _client.GetFromJsonAsync<JsonElement>("/api/sessions", HttpClientExtensions.JsonOptions);
        var match = closed.EnumerateArray().Single(item => item.GetProperty("id").GetGuid() == session.GetProperty("id").GetGuid());
        Assert.False(match.GetProperty("isActive").GetBoolean());
    }

    [Fact]
    public async Task EndSession_WhenMissing_ReturnsNotFound()
    {
        var response = await _client.PostAsync($"/api/sessions/{Guid.NewGuid()}/end", null);
        Assert.Equal(HttpStatusCode.NotFound, response.StatusCode);
    }

    private async Task<Guid> CreateSpaceAsync(string code)
    {
        var created = await _client.PostAsJsonAsync("/api/spaces", new
        {
            code,
            zoneId = CentroId,
            latitude = 19.4,
            longitude = -99.1,
            hourlyRate = 2
        });
        created.EnsureSuccessStatusCode();
        var space = await created.Content.ReadFromJsonAsync<JsonElement>(HttpClientExtensions.JsonOptions);
        return space.GetProperty("id").GetGuid();
    }
}
