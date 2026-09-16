using Parkimetro.Api.Billing;
using Parkimetro.Api.Models;

namespace Parkimetro.Api.Tests.Unit;

public class ParkingSettlementTests
{
    [Fact]
    public void Close_RecordsPaymentOnce()
    {
        var started = DateTimeOffset.Parse("2026-09-15T12:00:00Z");
        var ended = started.AddMinutes(10);
        var session = new ParkingSession { StartedAt = started };
        var space = new ParkingSpace { Code = "A-01", HourlyRate = 2 };

        ParkingSettlement.Close(session, space, ended);
        ParkingSettlement.Close(session, space, ended.AddHours(3));

        Assert.Equal(ended, session.EndedAt);
        Assert.Equal(1, session.BilledHours);
        Assert.Equal(2, session.Amount);
        Assert.Equal(2, session.ChargedRate);
    }
}
