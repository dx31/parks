using System.Net;
using System.Net.Http.Headers;
using System.Net.Http.Json;

namespace Parkimetro.Api.Tests.Integration;

public class AuthorizationApiTests : IClassFixture<ApiFactory>
{
    private readonly HttpClient _client;

    public AuthorizationApiTests(ApiFactory factory)
    {
        _client = factory.CreateClient();
    }

    [Theory]
    [InlineData("/api/zones")]
    [InlineData("/api/spaces")]
    [InlineData("/api/operators")]
    [InlineData("/api/sessions")]
    [InlineData("/api/cameras/demo")]
    [InlineData("/api/reports/earnings")]
    public async Task ProtectedEndpoints_WithoutToken_ReturnUnauthorized(string path)
    {
        var response = await _client.GetAsync(path);
        Assert.Equal(HttpStatusCode.Unauthorized, response.StatusCode);
    }

    [Fact]
    public async Task ProtectedEndpoints_WithInvalidToken_ReturnUnauthorized()
    {
        _client.DefaultRequestHeaders.Authorization = new AuthenticationHeaderValue("Bearer", "token-invalido");
        var response = await _client.GetAsync("/api/zones");
        Assert.Equal(HttpStatusCode.Unauthorized, response.StatusCode);
    }

    [Fact]
    public async Task LoginAndSwagger_RemainPublic()
    {
        var login = await _client.PostAsJsonAsync("/api/auth/login", new { username = "ana", pin = "1234" });
        Assert.Equal(HttpStatusCode.OK, login.StatusCode);

        var swagger = await _client.GetAsync("/swagger/index.html");
        Assert.Equal(HttpStatusCode.OK, swagger.StatusCode);

        var openApi = await _client.GetAsync("/openapi/v1.json");
        Assert.Equal(HttpStatusCode.OK, openApi.StatusCode);
    }
}
