using Parkimetro.Api.Billing;

namespace Parkimetro.Api.Tests.Unit;

public class ParkingBillingTests
{
    [Fact]
    public void HoursOrFraction_ChargesAtLeastOneHour()
    {
        var started = DateTimeOffset.Parse("2026-09-15T12:00:00Z");
        Assert.Equal(1, ParkingBilling.HoursOrFraction(started, started));
        Assert.Equal(1, ParkingBilling.HoursOrFraction(started, started.AddMinutes(1)));
        Assert.Equal(1, ParkingBilling.HoursOrFraction(started, started.AddHours(1)));
        Assert.Equal(2, ParkingBilling.HoursOrFraction(started, started.AddHours(1).AddSeconds(1)));
    }

    [Fact]
    public void Amount_UsesTwoSolesPerHourOrFraction()
    {
        var started = DateTimeOffset.Parse("2026-09-15T12:00:00Z");
        Assert.Equal(2, ParkingBilling.Amount(started, started.AddMinutes(10), 2));
        Assert.Equal(4, ParkingBilling.Amount(started, started.AddHours(1).AddMinutes(1), 2));
        Assert.Equal(2, ParkingBilling.Amount(started, started.AddMinutes(5), 0));
    }
}
