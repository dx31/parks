using Parkimetro.Api.Models;

namespace Parkimetro.Api.Dtos;

public record SpaceDto(
    Guid Id,
    string Code,
    Guid ZoneId,
    string ZoneName,
    double Latitude,
    double Longitude,
    decimal HourlyRate,
    SpaceStatus Status,
    string? Notes,
    DateTimeOffset UpdatedAt,
    Guid? ActiveSessionId,
    string? ClientDni,
    string? ClientRuc,
    string? ClientName);

public record CreateSpaceRequest(
    string Code,
    Guid ZoneId,
    double Latitude,
    double Longitude,
    decimal HourlyRate,
    string? Notes);

public record UpdateSpaceRequest(
    string Code,
    double Latitude,
    double Longitude,
    decimal HourlyRate,
    string? Notes);

public record ChangeStatusRequest(SpaceStatus Status, string? Dni);

public record ReserveSpaceRequest(string Dni);
