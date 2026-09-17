using Parkimetro.Api.Identity;
using Parkimetro.Api.Models;

namespace Parkimetro.Api.Parking;

public sealed record OccupationOutcome(int StatusCode, string? Message, ParkingSession? Session)
{
    public bool Succeeded => Session is not null;
}

public static class ParkingOccupation
{
    public static async Task<OccupationOutcome> StartAsync(
        IRucDirectory directory,
        ParkingSpace space,
        Guid operatorId,
        string? dni,
        string? clientName,
        string? licensePlate,
        DateTimeOffset? limitUntil,
        DateTimeOffset? now = null)
    {
        var startedAt = now ?? DateTimeOffset.UtcNow;
        if (space.Status == SpaceStatus.OutOfService)
        {
            return Fail(StatusCodes.Status400BadRequest, "El espacio está fuera de servicio.");
        }

        if (space.Sessions.Any(session => session.EndedAt is null))
        {
            return Fail(StatusCodes.Status409Conflict, "Ese espacio ya tiene una sesión activa.");
        }

        string clientDni;
        string clientRuc;
        string clientNameValue;
        DateTimeOffset effectiveLimit;
        var plate = ParkingStay.NormalizePlate(licensePlate) ?? space.LicensePlate;

        if (space.Status == SpaceStatus.Reserved)
        {
            var normalized = DniRuc.NormalizeDni(dni);
            if (normalized is null)
            {
                return Fail(StatusCodes.Status400BadRequest, "Indica el DNI del cliente que reservó.");
            }

            if (!string.Equals(normalized, space.ClientDni, StringComparison.Ordinal))
            {
                return Fail(StatusCodes.Status409Conflict, "El DNI no coincide con la reserva.");
            }

            clientDni = space.ClientDni!;
            clientRuc = space.ClientRuc ?? DniRuc.ToRuc(clientDni);
            clientNameValue = space.ClientName ?? string.Empty;
            var chosenLimit = limitUntil ?? space.LimitUntil;
            var reservedWindowError = ParkingStay.ValidateWindow(startedAt, chosenLimit);
            if (reservedWindowError is not null)
            {
                return Fail(StatusCodes.Status400BadRequest, reservedWindowError);
            }

            effectiveLimit = chosenLimit!.Value;
        }
        else
        {
            var lookup = await ClientLookup.ResolveAsync(directory, dni, clientName);
            if (!lookup.Succeeded)
            {
                return Fail(lookup.StatusCode, lookup.Message);
            }

            var windowError = ParkingStay.ValidateWindow(startedAt, limitUntil);
            if (windowError is not null)
            {
                return Fail(StatusCodes.Status400BadRequest, windowError);
            }

            clientDni = lookup.Dni!;
            clientRuc = lookup.Ruc!;
            clientNameValue = lookup.Name!;
            effectiveLimit = limitUntil!.Value;
        }

        ParkingStay.AssignClient(
            space,
            clientDni,
            clientRuc,
            clientNameValue,
            plate,
            space.ReservedFrom,
            effectiveLimit);
        space.Status = SpaceStatus.Occupied;
        space.UpdatedAt = startedAt;

        var session = new ParkingSession
        {
            Id = Guid.NewGuid(),
            SpaceId = space.Id,
            OperatorId = operatorId,
            LicensePlate = plate,
            StartedAt = startedAt,
            LimitUntil = effectiveLimit
        };

        return new OccupationOutcome(StatusCodes.Status201Created, null, session);
    }

    private static OccupationOutcome Fail(int statusCode, string? message) =>
        new(statusCode, message, null);
}
