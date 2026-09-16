using Microsoft.EntityFrameworkCore;
using Parkimetro.Api.Data;

namespace Parkimetro.Api.Tests.Unit;

public class SchemaPatcherTests
{
    [Fact]
    public async Task ApplyAsync_AddsMissingColumnsOnSqlite()
    {
        var path = Path.Combine(Path.GetTempPath(), $"parkimetro-schema-{Guid.NewGuid():N}.db");
        var options = new DbContextOptionsBuilder<AppDbContext>()
            .UseSqlite($"Data Source={path}")
            .Options;
        await using (var db = new AppDbContext(options))
        {
            await db.Database.OpenConnectionAsync();
            await db.Database.ExecuteSqlRawAsync("CREATE TABLE Zones (Id TEXT PRIMARY KEY, Name TEXT, City TEXT)");
            await db.Database.ExecuteSqlRawAsync("CREATE TABLE Spaces (Id TEXT PRIMARY KEY, Code TEXT)");
            await db.Database.ExecuteSqlRawAsync("CREATE TABLE Sessions (Id TEXT PRIMARY KEY, SpaceId TEXT, OperatorId TEXT, StartedAt TEXT, EndedAt TEXT)");

            await SchemaPatcher.ApplyAsync(db);
            await SchemaPatcher.ApplyAsync(db);

            Assert.True(await ColumnExists(db, "Zones", "VideoUrl"));
            Assert.True(await ColumnExists(db, "Spaces", "ClientDni"));
            Assert.True(await ColumnExists(db, "Spaces", "ClientName"));
            Assert.True(await ColumnExists(db, "Spaces", "LicensePlate"));
            Assert.True(await ColumnExists(db, "Spaces", "ReservedFrom"));
            Assert.True(await ColumnExists(db, "Spaces", "LimitUntil"));
            Assert.True(await ColumnExists(db, "Sessions", "Amount"));
            Assert.True(await ColumnExists(db, "Sessions", "BilledHours"));
            Assert.True(await ColumnExists(db, "Sessions", "ChargedRate"));
            Assert.True(await ColumnExists(db, "Sessions", "LimitUntil"));
            await db.Database.CloseConnectionAsync();
        }

        try
        {
            File.Delete(path);
        }
        catch (IOException)
        {
            // SQLite can keep a short lock on Windows.
        }
    }

    [Fact]
    public async Task ApplyAsync_IgnoresNonSqliteProviders()
    {
        var options = new DbContextOptionsBuilder<AppDbContext>()
            .UseInMemoryDatabase(Guid.NewGuid().ToString())
            .Options;
        await using var db = new AppDbContext(options);
        await SchemaPatcher.ApplyAsync(db);
    }

    private static async Task<bool> ColumnExists(AppDbContext db, string table, string column)
    {
        await using var command = db.Database.GetDbConnection().CreateCommand();
        command.CommandText = $"""PRAGMA table_info("{table}")""";
        await using var reader = await command.ExecuteReaderAsync();
        while (await reader.ReadAsync())
        {
            if (string.Equals(reader.GetString(1), column, StringComparison.OrdinalIgnoreCase))
            {
                return true;
            }
        }

        return false;
    }
}
