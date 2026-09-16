using Parkimetro.Api.Billing;
using Parkimetro.Api.Dtos;
using Parkimetro.Api.Identity;
using Parkimetro.Api.Models;
using Parkimetro.Api.Parking;

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

    public static SpaceDto ToDto(this ParkingSpace space)
    {
        var active = space.Sessions.FirstOrDefault(session => session.EndedAt is null);
        return new(
            space.Id,
            space.Code,
            space.ZoneId,
            space.Zone?.Name ?? string.Empty,
            space.Latitude,
            space.Longitude,
            ParkingBilling.EffectiveRate(space.HourlyRate),
            space.Status,
            space.Notes,
            space.UpdatedAt,
            active?.Id,
            space.ClientDni,
            space.ClientRuc,
            space.ClientName,
            active?.StartedAt,
            space.LicensePlate ?? active?.LicensePlate,
            space.ReservedFrom,
            space.LimitUntil ?? active?.LimitUntil,
            ParkingStay.Exceeded(space));
    }

    public static SessionDto ToDto(this ParkingSession session, DateTimeOffset? now = null)
    {
        var until = session.EndedAt ?? now ?? DateTimeOffset.UtcNow;
        var rate = session.ChargedRate ?? ParkingBilling.EffectiveRate(session.Space?.HourlyRate ?? 0);
        var hours = session.BilledHours ?? ParkingBilling.HoursOrFraction(session.StartedAt, until);
        var amount = session.Amount ?? ParkingBilling.Amount(session.StartedAt, until, rate);
        return new(
            session.Id,
            session.SpaceId,
            session.Space?.Code ?? string.Empty,
            session.OperatorId,
            session.Operator?.Name ?? string.Empty,
            session.LicensePlate,
            session.StartedAt,
            session.LimitUntil,
            session.EndedAt,
            session.IsActive,
            hours,
            amount,
            rate,
            session.EndedAt is not null && session.Amount is not null);
    }

    public static ClientIdentityDto ToDto(this ClientIdentity identity) =>
        new(identity.Dni, identity.Ruc, identity.Name, identity.Address);
}
