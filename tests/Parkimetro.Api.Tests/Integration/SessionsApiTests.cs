using System.Net;
using System.Net.Http.Json;
using System.Text.Json;

namespace Parkimetro.Api.Tests.Integration;

public class SessionsApiTests : IClassFixture<ApiFactory>
{
    private static readonly Guid CentroId = Guid.Parse("11111111-1111-1111-1111-111111111111");
    private readonly HttpClient _client;

    public SessionsApiTests(ApiFactory factory)
    {
        _client = factory.CreateClient();
    }

    [Fact]
    public async Task StartSession_RequiresOperator()
    {
        var response = await _client.PostAsJsonAsync("/api/sessions", new { spaceId = Guid.NewGuid() });
        Assert.Equal(HttpStatusCode.Unauthorized, response.StatusCode);
    }

    [Fact]
    public async Task SessionLifecycle_OccupiesAndReleasesSpace()
    {
        await _client.LoginAsAnaAsync();
        var spaceId = await CreateSpaceAsync("S-01");

        var started = await _client.PostAsJsonAsync("/api/sessions", new { spaceId, licensePlate = " abc123 " });
        Assert.Equal(HttpStatusCode.Created, started.StatusCode);
        var session = await started.Content.ReadFromJsonAsync<JsonElement>(HttpClientExtensions.JsonOptions);
        Assert.Equal("ABC123", session.GetProperty("licensePlate").GetString());
        Assert.True(session.GetProperty("isActive").GetBoolean());

        var space = await _client.GetFromJsonAsync<JsonElement>($"/api/spaces/{spaceId}", HttpClientExtensions.JsonOptions);
        Assert.Equal("occupied", space.GetProperty("status").GetString());

        var conflict = await _client.PostAsJsonAsync("/api/sessions", new { spaceId });
        Assert.Equal(HttpStatusCode.Conflict, conflict.StatusCode);

        var active = await _client.GetFromJsonAsync<JsonElement>("/api/sessions?activeOnly=true", HttpClientExtensions.JsonOptions);
        Assert.True(active.GetArrayLength() >= 1);

        var sessionId = session.GetProperty("id").GetGuid();
        var ended = await _client.PostAsync($"/api/sessions/{sessionId}/end", null);
        Assert.Equal(HttpStatusCode.OK, ended.StatusCode);

        var released = await _client.GetFromJsonAsync<JsonElement>($"/api/spaces/{spaceId}", HttpClientExtensions.JsonOptions);
        Assert.Equal("free", released.GetProperty("status").GetString());

        var alreadyEnded = await _client.PostAsync($"/api/sessions/{sessionId}/end", null);
        Assert.Equal(HttpStatusCode.BadRequest, alreadyEnded.StatusCode);
    }

    [Fact]
    public async Task StartSession_WhenSpaceMissingOrOutOfService_Fails()
    {
        await _client.LoginAsAnaAsync();

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
        await _client.LoginAsAnaAsync();
        var spaceId = await CreateSpaceAsync("S-02");
        var started = await _client.PostAsJsonAsync("/api/sessions", new { spaceId });
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
        await _client.LoginAsAnaAsync();
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
            hourlyRate = 18
        });
        created.EnsureSuccessStatusCode();
        var space = await created.Content.ReadFromJsonAsync<JsonElement>(HttpClientExtensions.JsonOptions);
        return space.GetProperty("id").GetGuid();
    }
}
