using Parkimetro.Api.Dtos;
using Parkimetro.Api.Identity;
using Parkimetro.Api.Models;

namespace Parkimetro.Api.Mapping;

public static class EntityMapper
{
    public static ZoneDto ToDto(this Zone zone) =>
        new(
            zone.Id,
            zone.Name,
            zone.City,
            zone.Spaces.Count,
            zone.Spaces.Count(space => space.Status == SpaceStatus.Free),
            zone.VideoUrl);

    public static SpaceDto ToDto(this ParkingSpace space) =>
        new(
            space.Id,
            space.Code,
            space.ZoneId,
            space.Zone?.Name ?? string.Empty,
            space.Latitude,
            space.Longitude,
            space.HourlyRate,
            space.Status,
            space.Notes,
            space.UpdatedAt,
            space.Sessions.FirstOrDefault(session => session.EndedAt is null)?.Id,
            space.ClientDni,
            space.ClientRuc,
            space.ClientName);

    public static SessionDto ToDto(this ParkingSession session) =>
        new(
            session.Id,
            session.SpaceId,
            session.Space?.Code ?? string.Empty,
            session.OperatorId,
            session.Operator?.Name ?? string.Empty,
            session.LicensePlate,
            session.StartedAt,
            session.EndedAt,
            session.IsActive);

    public static ClientIdentityDto ToDto(this ClientIdentity identity) =>
        new(identity.Dni, identity.Ruc, identity.Name, identity.Address);
}
