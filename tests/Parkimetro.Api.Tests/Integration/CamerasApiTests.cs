using System.Net;

namespace Parkimetro.Api.Tests.Integration;

public class CamerasApiTests : IClassFixture<ApiFactory>, IAsyncLifetime
{
    private readonly HttpClient _client;

    public CamerasApiTests(ApiFactory factory)
    {
        _client = factory.CreateClient();
    }

    public Task InitializeAsync() => _client.LoginAsAnaAsync();

    public Task DisposeAsync() => Task.CompletedTask;

    [Fact]
    public async Task GetCamera_ReturnsMp4ForDemo()
    {
        var response = await _client.GetAsync("/api/cameras/demo");
        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
        Assert.Equal("video/mp4", response.Content.Headers.ContentType?.MediaType);
        var bytes = await response.Content.ReadAsByteArrayAsync();
        Assert.True(bytes.Length > 100);
    }

    [Fact]
    public async Task GetCamera_WhenMissingOrInvalid_Fails()
    {
        var missing = await _client.GetAsync("/api/cameras/no-existe");
        Assert.Equal(HttpStatusCode.NotFound, missing.StatusCode);

        var invalid = await _client.GetAsync("/api/cameras/foo.bar");
        Assert.Equal(HttpStatusCode.BadRequest, invalid.StatusCode);
    }
}
