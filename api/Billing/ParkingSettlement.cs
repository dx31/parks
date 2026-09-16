using Parkimetro.Api.Models;

namespace Parkimetro.Api.Billing;

public static class ParkingSettlement
{
    public static void Close(ParkingSession session, ParkingSpace? space, DateTimeOffset endedAt)
    {
        if (session.EndedAt is not null)
        {
            return;
        }

        var rate = ParkingBilling.EffectiveRate(space?.HourlyRate ?? 0);
        session.EndedAt = endedAt;
        session.ChargedRate = rate;
        session.BilledHours = ParkingBilling.HoursOrFraction(session.StartedAt, endedAt);
        session.Amount = ParkingBilling.Amount(session.StartedAt, endedAt, rate);
    }
}
