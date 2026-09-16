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
        await AddColumnIfMissingAsync(db, "Spaces", "LicensePlate", """ALTER TABLE "Spaces" ADD COLUMN "LicensePlate" TEXT""");
        await AddColumnIfMissingAsync(db, "Spaces", "ReservedFrom", """ALTER TABLE "Spaces" ADD COLUMN "ReservedFrom" TEXT""");
        await AddColumnIfMissingAsync(db, "Spaces", "LimitUntil", """ALTER TABLE "Spaces" ADD COLUMN "LimitUntil" TEXT""");
        await AddColumnIfMissingAsync(db, "Sessions", "BilledHours", """ALTER TABLE "Sessions" ADD COLUMN "BilledHours" INTEGER""");
        await AddColumnIfMissingAsync(db, "Sessions", "Amount", """ALTER TABLE "Sessions" ADD COLUMN "Amount" TEXT""");
        await AddColumnIfMissingAsync(db, "Sessions", "ChargedRate", """ALTER TABLE "Sessions" ADD COLUMN "ChargedRate" TEXT""");
        await AddColumnIfMissingAsync(db, "Sessions", "LimitUntil", """ALTER TABLE "Sessions" ADD COLUMN "LimitUntil" TEXT""");
    }

    private static async Task AddColumnIfMissingAsync(AppDbContext db, string table, string column, string sql)
    {
        if (!await TableExistsAsync(db, table) || await ColumnExistsAsync(db, table, column))
        {
            return;
        }

        await db.Database.ExecuteSqlRawAsync(sql);
    }

    private static async Task<bool> TableExistsAsync(AppDbContext db, string table)
    {
        await using var command = db.Database.GetDbConnection().CreateCommand();
        if (command.Connection!.State != System.Data.ConnectionState.Open)
        {
            await command.Connection.OpenAsync();
        }

        if (table is not ("Zones" or "Spaces" or "Sessions"))
        {
            throw new ArgumentOutOfRangeException(nameof(table), table, "Tabla no soportada.");
        }

        command.CommandText = $"""SELECT 1 FROM sqlite_master WHERE type = 'table' AND name = '{table}'""";
        var result = await command.ExecuteScalarAsync();
        return result is not null && result is not DBNull;
    }

    private static async Task<bool> ColumnExistsAsync(AppDbContext db, string table, string column)
    {
        await using var command = db.Database.GetDbConnection().CreateCommand();
        if (command.Connection!.State != System.Data.ConnectionState.Open)
        {
            await command.Connection.OpenAsync();
        }

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
