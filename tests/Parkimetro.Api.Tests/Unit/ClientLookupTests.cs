using Parkimetro.Api.Identity;

namespace Parkimetro.Api.Tests.Unit;

public class ClientLookupTests
{
    [Fact]
    public async Task ResolveAsync_RequiresEightDigitDni()
    {
        var result = await ClientLookup.ResolveAsync(new InMemoryRucDirectory(), "123", null);
        Assert.False(result.Succeeded);
        Assert.Equal(StatusCodes.Status400BadRequest, result.StatusCode);
    }

    [Fact]
    public async Task ResolveAsync_UsesDirectoryName()
    {
        var result = await ClientLookup.ResolveAsync(new InMemoryRucDirectory(), "12345678", null);
        Assert.True(result.Succeeded);
        Assert.Equal("PEREZ PEREZ JUAN", result.Name);
        Assert.Equal("10123456780", result.Ruc);
    }

    [Fact]
    public async Task ResolveAsync_AllowsManualNameWhenUnknown()
    {
        var missing = await ClientLookup.ResolveAsync(new InMemoryRucDirectory(), "00000000", null);
        Assert.False(missing.Succeeded);

        var manual = await ClientLookup.ResolveAsync(new InMemoryRucDirectory(), "00000000", "  JUAN MANUAL  ");
        Assert.True(manual.Succeeded);
        Assert.Equal("JUAN MANUAL", manual.Name);
    }

    [Fact]
    public async Task ResolveAsync_WhenDirectoryFailsWithoutName_ReturnsUnavailable()
    {
        var result = await ClientLookup.ResolveAsync(new FailingDirectory(), "12345678", null);
        Assert.Equal(StatusCodes.Status503ServiceUnavailable, result.StatusCode);

        var fallback = await ClientLookup.ResolveAsync(new FailingDirectory(), "12345678", "ANA");
        Assert.True(fallback.Succeeded);
        Assert.Equal("ANA", fallback.Name);
    }

    private sealed class FailingDirectory : IRucDirectory
    {
        public Task<ClientIdentity?> FindByDniAsync(string dni, CancellationToken cancellationToken = default) =>
            throw new InvalidOperationException("padrón caído");
    }
}
