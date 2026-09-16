using System.Net;
using System.Net.Http.Json;
using System.Text.Json;

namespace Parkimetro.Api.Tests.Integration;

public class ReportsApiTests : IClassFixture<ApiFactory>, IAsyncLifetime
{
    private static readonly Guid CentroId = Guid.Parse("11111111-1111-1111-1111-111111111111");
    private readonly HttpClient _client;

    public ReportsApiTests(ApiFactory factory)
    {
        _client = factory.CreateClient();
    }

    public Task InitializeAsync() => _client.LoginAsAnaAsync();

    public Task DisposeAsync() => Task.CompletedTask;

    [Fact]
    public async Task Earnings_IncludesReleasedSessionsAsPaid()
    {
        var created = await _client.PostAsJsonAsync("/api/spaces", new
        {
            code = "G-01",
            zoneId = CentroId,
            latitude = 19.4,
            longitude = -99.1,
            hourlyRate = 2
        });
        created.EnsureSuccessStatusCode();
        var space = await created.Content.ReadFromJsonAsync<JsonElement>(HttpClientExtensions.JsonOptions);
        var spaceId = space.GetProperty("id").GetGuid();

        var started = await _client.PostAsJsonAsync(
            "/api/sessions",
            HttpClientExtensions.OccupyPayload(spaceId, "12345678"));
        started.EnsureSuccessStatusCode();
        var session = await started.Content.ReadFromJsonAsync<JsonElement>(HttpClientExtensions.JsonOptions);
        var sessionId = session.GetProperty("id").GetGuid();

        var ended = await _client.PostAsync($"/api/sessions/{sessionId}/end", null);
        ended.EnsureSuccessStatusCode();

        var report = await _client.GetFromJsonAsync<JsonElement>("/api/reports/earnings", HttpClientExtensions.JsonOptions);
        Assert.True(report.GetProperty("paymentsCount").GetInt32() >= 1);
        Assert.True(report.GetProperty("totalAmount").GetDecimal() >= 2);

        var payments = report.GetProperty("payments");
        var match = payments.EnumerateArray().Single(item => item.GetProperty("id").GetGuid() == sessionId);
        Assert.True(match.GetProperty("paid").GetBoolean());
        Assert.Equal(2, match.GetProperty("amount").GetDecimal());
        Assert.Equal("G-01", match.GetProperty("spaceCode").GetString());
    }
}
