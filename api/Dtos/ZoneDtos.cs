namespace Parkimetro.Api.Dtos;

public record ZoneDto(Guid Id, string Name, string City, int SpacesCount, int FreeCount, string? VideoUrl);

public record CreateZoneRequest(string Name, string City, string? VideoUrl);

public record UpdateZoneRequest(string Name, string City, string? VideoUrl);
