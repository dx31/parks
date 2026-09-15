using Microsoft.Extensions.Options;
using MySqlConnector;

namespace Parkimetro.Api.Identity;

public sealed class MariaDbRucDirectory(IOptions<RucDirectoryOptions> options) : IRucDirectory
{
    private readonly RucDirectoryOptions _options = options.Value;

    public async Task<ClientIdentity?> FindByDniAsync(string dni, CancellationToken cancellationToken = default)
    {
        var normalized = DniRuc.NormalizeDni(dni);
        if (normalized is null)
        {
            return null;
        }

        var ruc = DniRuc.ToRuc(normalized);
        try
        {
            await using var connection = new MySqlConnection(_options.ConnectionString);
            await connection.OpenAsync(cancellationToken);
            return await QueryByRucAsync(connection, normalized, ruc, cancellationToken)
                ?? await QueryByDniPrefixAsync(connection, normalized, cancellationToken);
        }
        catch (MySqlException exception)
        {
            throw new InvalidOperationException("No se pudo consultar el padrón RUC.", exception);
        }
    }

    private async Task<ClientIdentity?> QueryByRucAsync(
        MySqlConnection connection,
        string dni,
        string ruc,
        CancellationToken cancellationToken)
    {
        await using var command = connection.CreateCommand();
        command.CommandText = SelectSql("WHERE `{0}` = @ruc");
        command.Parameters.AddWithValue("@ruc", ruc);
        return await ReadIdentityAsync(command, dni, cancellationToken);
    }

    private async Task<ClientIdentity?> QueryByDniPrefixAsync(
        MySqlConnection connection,
        string dni,
        CancellationToken cancellationToken)
    {
        await using var command = connection.CreateCommand();
        command.CommandText = SelectSql("WHERE `{0}` LIKE @prefix LIMIT 1");
        command.Parameters.AddWithValue("@prefix", $"10{dni}%");
        return await ReadIdentityAsync(command, dni, cancellationToken);
    }

    private string SelectSql(string whereClause)
    {
        var addressSelect = string.IsNullOrWhiteSpace(_options.AddressColumn)
            ? "NULL"
            : $"`{_options.AddressColumn}`";

        return $"""
            SELECT `{_options.RucColumn}`, `{_options.NameColumn}`, {addressSelect}
            FROM `{_options.Table}`
            {string.Format(whereClause, _options.RucColumn)}
            """;
    }

    private static async Task<ClientIdentity?> ReadIdentityAsync(
        MySqlCommand command,
        string dni,
        CancellationToken cancellationToken)
    {
        await using var reader = await command.ExecuteReaderAsync(cancellationToken);
        if (!await reader.ReadAsync(cancellationToken))
        {
            return null;
        }

        var ruc = reader.GetString(0).Trim();
        var name = reader.IsDBNull(1) ? string.Empty : reader.GetString(1).Trim();
        var address = reader.FieldCount > 2 && !reader.IsDBNull(2) ? reader.GetString(2).Trim() : null;
        if (string.IsNullOrWhiteSpace(name))
        {
            return null;
        }

        return new ClientIdentity(dni, ruc, name, string.IsNullOrWhiteSpace(address) ? null : address);
    }
}
