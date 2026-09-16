namespace Parkimetro.Api.Billing;

public static class ParkingBilling
{
    public const decimal DefaultHourlyRate = 2m;

    public static int HoursOrFraction(DateTimeOffset startedAt, DateTimeOffset endedAt)
    {
        var elapsed = endedAt - startedAt;
        if (elapsed <= TimeSpan.Zero)
        {
            return 1;
        }

        var hours = (int)Math.Ceiling(elapsed.TotalHours);
        return hours < 1 ? 1 : hours;
    }

    public static decimal Amount(DateTimeOffset startedAt, DateTimeOffset endedAt, decimal hourlyRate)
    {
        var rate = hourlyRate > 0 ? hourlyRate : DefaultHourlyRate;
        return HoursOrFraction(startedAt, endedAt) * rate;
    }

    public static decimal EffectiveRate(decimal hourlyRate) =>
        hourlyRate > 0 ? hourlyRate : DefaultHourlyRate;
}
