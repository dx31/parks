using Microsoft.Extensions.Options;
using Parkimetro.Api.Identity;

namespace Parkimetro.Api.Tests.Unit;

public class RucDirectoryTests
{
    [Fact]
    public async Task InMemoryDirectory_FindsSeededDni()
    {
        var directory = new InMemoryRucDirectory();
        var identity = await directory.FindByDniAsync("12345678");
        Assert.NotNull(identity);
        Assert.Equal("PEREZ PEREZ JUAN", identity.Name);
        Assert.Equal("10123456780", identity.Ruc);
        Assert.Null(await directory.FindByDniAsync("00000000"));
        Assert.Null(await directory.FindByDniAsync("12"));
    }

    [Fact]
    public async Task MariaDbDirectory_WhenDniInvalid_DoesNotConnect()
    {
        var directory = new MariaDbRucDirectory(Options.Create(new RucDirectoryOptions
        {
            ConnectionString = "Server=127.0.0.1;Port=1;Database=none;User=none;Password=none;"
        }));

        Assert.Null(await directory.FindByDniAsync("123"));
    }
}
