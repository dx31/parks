namespace Parkimetro.Api.Identity;

public interface IRucDirectory
{
    Task<ClientIdentity?> FindByDniAsync(string dni, CancellationToken cancellationToken = default);
}
