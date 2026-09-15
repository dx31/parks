namespace Parkimetro.Api.Identity;

public sealed class InMemoryRucDirectory : IRucDirectory
{
    private readonly Dictionary<string, ClientIdentity> _byDni;

    public InMemoryRucDirectory()
    {
        const string dni = "12345678";
        _byDni = new Dictionary<string, ClientIdentity>(StringComparer.Ordinal)
        {
            [dni] = new ClientIdentity(dni, DniRuc.ToRuc(dni), "PEREZ PEREZ JUAN")
        };
    }

    public Task<ClientIdentity?> FindByDniAsync(string dni, CancellationToken cancellationToken = default)
    {
        var normalized = DniRuc.NormalizeDni(dni);
        if (normalized is null)
        {
            return Task.FromResult<ClientIdentity?>(null);
        }

        _byDni.TryGetValue(normalized, out var identity);
        return Task.FromResult(identity);
    }
}
