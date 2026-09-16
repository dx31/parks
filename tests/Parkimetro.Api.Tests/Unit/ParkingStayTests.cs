using Microsoft.AspNetCore.Http;
using Parkimetro.Api.Identity;
using Parkimetro.Api.Models;
using Parkimetro.Api.Parking;

namespace Parkimetro.Api.Tests.Unit;

public class ParkingStayTests
{
    [Fact]
    public void ValidateWindow_RequiresLimitAfterStart()
    {
        var start = DateTimeOffset.Parse("2026-09-16T12:00:00Z");
        Assert.Equal("Indica la hora límite.", ParkingStay.ValidateWindow(start, null));
        Assert.Equal("La hora límite debe ser posterior al inicio.", ParkingStay.ValidateWindow(start, start));
        Assert.Null(ParkingStay.ValidateWindow(start, start.AddHours(1)));
    }

    [Fact]
    public void Exceeded_WhenLimitPassedAndReservedOrOccupied()
    {
        var now = DateTimeOffset.Parse("2026-09-16T15:00:00Z");
        var space = new ParkingSpace
        {
            Code = "A-01",
            Status = SpaceStatus.Occupied,
            LimitUntil = now.AddMinutes(-1)
        };

        Assert.True(ParkingStay.Exceeded(space, now));
        space.Status = SpaceStatus.Reserved;
        Assert.True(ParkingStay.Exceeded(space, now));
        space.Status = SpaceStatus.Free;
        Assert.False(ParkingStay.Exceeded(space, now));
    }

    [Fact]
    public void AssignAndClear_ClientStayFields()
    {
        var space = new ParkingSpace { Code = "A-01" };
        var start = DateTimeOffset.UtcNow;
        ParkingStay.AssignClient(space, "12345678", "10123456780", "ANA", "ABC123", start, start.AddHours(2));
        Assert.Equal("ABC123", space.LicensePlate);
        Assert.Equal(start, space.ReservedFrom);

        ParkingStay.Clear(space);
        Assert.Null(space.ClientDni);
        Assert.Null(space.LicensePlate);
        Assert.Null(space.LimitUntil);
    }
}

public class ParkingOccupationTests
{
    [Fact]
    public async Task StartAsync_OnFreeSpace_RequiresClientAndLimit()
    {
        var space = FreeSpace();
        var missing = await ParkingOccupation.StartAsync(
            new InMemoryRucDirectory(),
            space,
            Guid.NewGuid(),
            null,
            null,
            "ABC123",
            DateTimeOffset.UtcNow.AddHours(1));
        Assert.Equal(StatusCodes.Status400BadRequest, missing.StatusCode);

        var started = await ParkingOccupation.StartAsync(
            new InMemoryRucDirectory(),
            space,
            Guid.NewGuid(),
            "12345678",
            null,
            " abc123 ",
            DateTimeOffset.UtcNow.AddHours(2));
        Assert.True(started.Succeeded);
        Assert.Equal(SpaceStatus.Occupied, space.Status);
        Assert.Equal("ABC123", started.Session!.LicensePlate);
        Assert.Equal("PEREZ PEREZ JUAN", space.ClientName);
        Assert.Equal(started.Session.StartedAt, space.UpdatedAt);
    }

    [Fact]
    public async Task StartAsync_OnReservedSpace_RequiresMatchingDni()
    {
        var limit = DateTimeOffset.UtcNow.AddHours(2);
        var space = new ParkingSpace
        {
            Id = Guid.NewGuid(),
            Code = "B-02",
            Status = SpaceStatus.Reserved,
            ClientDni = "12345678",
            ClientRuc = "10123456780",
            ClientName = "PEREZ PEREZ JUAN",
            LimitUntil = limit
        };

        var wrong = await ParkingOccupation.StartAsync(
            new InMemoryRucDirectory(),
            space,
            Guid.NewGuid(),
            "87654321",
            null,
            null,
            null);
        Assert.Equal(StatusCodes.Status409Conflict, wrong.StatusCode);

        var claimed = await ParkingOccupation.StartAsync(
            new InMemoryRucDirectory(),
            space,
            Guid.NewGuid(),
            "12345678",
            null,
            "XYZ99",
            null);
        Assert.True(claimed.Succeeded);
        Assert.Equal(limit, claimed.Session!.LimitUntil);
        Assert.Equal("XYZ99", space.LicensePlate);
        Assert.Equal(SpaceStatus.Occupied, space.Status);
    }

    private static ParkingSpace FreeSpace() =>
        new()
        {
            Id = Guid.NewGuid(),
            Code = "A-01",
            Status = SpaceStatus.Free
        };
}
