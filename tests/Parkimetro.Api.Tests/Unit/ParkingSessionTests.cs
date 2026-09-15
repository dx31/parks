using Parkimetro.Api.Models;

namespace Parkimetro.Api.Tests.Unit;

public class ParkingSessionTests
{
    [Fact]
    public void IsActive_WhenEndedAtMissing_IsTrue()
    {
        var session = new ParkingSession { EndedAt = null };
        Assert.True(session.IsActive);
    }

    [Fact]
    public void IsActive_WhenEndedAtPresent_IsFalse()
    {
        var session = new ParkingSession { EndedAt = DateTimeOffset.UtcNow };
        Assert.False(session.IsActive);
    }
}
