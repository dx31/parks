using Microsoft.EntityFrameworkCore;
using Parkimetro.Api.Data;

namespace Parkimetro.Api.Tests.Unit;

public class DbSeederTests
{
    [Fact]
    public async Task SeedAsync_InsertsCatalogOnce()
    {
        await using var db = CreateDb();

        await DbSeeder.SeedAsync(db);
        await DbSeeder.SeedAsync(db);

        Assert.Equal(2, await db.Zones.CountAsync());
        Assert.Equal(6, await db.Spaces.CountAsync());
        Assert.Equal(1, await db.Operators.CountAsync());
        Assert.Equal("ana", (await db.Operators.SingleAsync()).Username);
    }

    private static AppDbContext CreateDb()
    {
        var options = new DbContextOptionsBuilder<AppDbContext>()
            .UseInMemoryDatabase(Guid.NewGuid().ToString())
            .Options;
        return new AppDbContext(options);
    }
}
