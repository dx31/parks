namespace Parkimetro.Api.Identity;

public record ClientIdentity(string Dni, string Ruc, string Name, string? Address = null);
