using Parkimetro.Api.Models;

namespace Parkimetro.Api.Parking;

public static class ParkingStay
{
    public static string? ValidateWindow(DateTimeOffset start, DateTimeOffset? limitUntil)
    {
        if (limitUntil is null)
        {
            return "Indica la hora límite.";
        }

        if (limitUntil.Value <= start)
        {
            return "La hora límite debe ser posterior al inicio.";
        }

        return null;
    }

    public static string? NormalizePlate(string? plate) =>
        string.IsNullOrWhiteSpace(plate) ? null : plate.Trim().ToUpperInvariant();

    public static bool Exceeded(ParkingSpace space, DateTimeOffset? now = null) =>
        space.LimitUntil is not null
        && space.Status is SpaceStatus.Occupied or SpaceStatus.Reserved
        && (now ?? DateTimeOffset.UtcNow) > space.LimitUntil.Value;

    public static void AssignClient(
        ParkingSpace space,
        string dni,
        string ruc,
        string name,
        string? licensePlate,
        DateTimeOffset? reservedFrom,
        DateTimeOffset limitUntil)
    {
        space.ClientDni = dni;
        space.ClientRuc = ruc;
        space.ClientName = name;
        space.LicensePlate = licensePlate;
        space.ReservedFrom = reservedFrom;
        space.LimitUntil = limitUntil;
        space.UpdatedAt = DateTimeOffset.UtcNow;
    }

    public static void Clear(ParkingSpace space)
    {
        space.ClientDni = null;
        space.ClientRuc = null;
        space.ClientName = null;
        space.LicensePlate = null;
        space.ReservedFrom = null;
        space.LimitUntil = null;
    }
}
