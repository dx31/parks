namespace Parkimetro.Api.Identity;

public sealed record ClientLookupOutcome(int StatusCode, string? Message, string? Dni, string? Ruc, string? Name)
{
    public bool Succeeded => StatusCode is >= 200 and < 300;
}

public static class ClientLookup
{
    public static async Task<ClientLookupOutcome> ResolveAsync(
        IRucDirectory directory,
        string? dni,
        string? clientName,
        CancellationToken cancellationToken = default)
    {
        var normalized = DniRuc.NormalizeDni(dni);
        if (normalized is null)
        {
            return new(StatusCodes.Status400BadRequest, "Indica el DNI de 8 dígitos del cliente.", null, null, null);
        }

        ClientIdentity? found = null;
        try
        {
            found = await directory.FindByDniAsync(normalized, cancellationToken);
        }
        catch (InvalidOperationException exception)
        {
            if (string.IsNullOrWhiteSpace(clientName))
            {
                return new(StatusCodes.Status503ServiceUnavailable, exception.Message, null, null, null);
            }
        }

        var name = string.IsNullOrWhiteSpace(found?.Name) ? clientName?.Trim() : found!.Name;
        if (string.IsNullOrWhiteSpace(name))
        {
            return new(StatusCodes.Status400BadRequest, "No se encontró el nombre. Ingrésalo manualmente.", null, null, null);
        }

        return new(StatusCodes.Status200OK, null, normalized, found?.Ruc ?? DniRuc.ToRuc(normalized), name);
    }
}
