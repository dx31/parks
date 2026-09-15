using Microsoft.EntityFrameworkCore;

namespace Parkimetro.Api.Data;

public static class SchemaPatcher
{
    public static async Task ApplyAsync(AppDbContext db)
    {
        if (db.Database.ProviderName is not "Microsoft.EntityFrameworkCore.Sqlite")
        {
            return;
        }

        await AddColumnIfMissingAsync(db, "Zones", "VideoUrl", """ALTER TABLE "Zones" ADD COLUMN "VideoUrl" TEXT""");
        await AddColumnIfMissingAsync(db, "Spaces", "ClientDni", """ALTER TABLE "Spaces" ADD COLUMN "ClientDni" TEXT""");
        await AddColumnIfMissingAsync(db, "Spaces", "ClientRuc", """ALTER TABLE "Spaces" ADD COLUMN "ClientRuc" TEXT""");
        await AddColumnIfMissingAsync(db, "Spaces", "ClientName", """ALTER TABLE "Spaces" ADD COLUMN "ClientName" TEXT""");
    }

    private static async Task AddColumnIfMissingAsync(AppDbContext db, string table, string column, string sql)
    {
        if (await ColumnExistsAsync(db, table, column))
        {
            return;
        }

        await db.Database.ExecuteSqlRawAsync(sql);
    }

    private static async Task<bool> ColumnExistsAsync(AppDbContext db, string table, string column)
    {
        await using var command = db.Database.GetDbConnection().CreateCommand();
        if (command.Connection!.State != System.Data.ConnectionState.Open)
        {
            await command.Connection.OpenAsync();
        }

        command.CommandText = table switch
        {
            "Zones" => """PRAGMA table_info("Zones")""",
            "Spaces" => """PRAGMA table_info("Spaces")""",
            _ => throw new ArgumentOutOfRangeException(nameof(table), table, "Tabla no soportada.")
        };
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
