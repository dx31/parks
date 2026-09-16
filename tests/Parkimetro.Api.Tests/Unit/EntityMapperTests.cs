using Parkimetro.Api.Mapping;
using Parkimetro.Api.Models;

namespace Parkimetro.Api.Tests.Unit;

public class EntityMapperTests
{
    [Fact]
    public void ZoneToDto_CountsFreeSpaces()
    {
        var zone = new Zone
        {
            Id = Guid.NewGuid(),
            Name = "Centro",
            City = "Ciudad",
            Spaces =
            [
                new ParkingSpace { Code = "A-01", Status = SpaceStatus.Free },
                new ParkingSpace { Code = "A-02", Status = SpaceStatus.Occupied }
            ]
        };

        var dto = zone.ToDto();

        Assert.Equal(2, dto.SpacesCount);
        Assert.Equal(1, dto.FreeCount);
        Assert.Null(dto.VideoUrl);
    }

    [Fact]
    public void SpaceToDto_UsesEmptyZoneNameAndActiveSession()
    {
        var sessionId = Guid.NewGuid();
        var space = new ParkingSpace
        {
            Id = Guid.NewGuid(),
            Code = "B-01",
            ZoneId = Guid.NewGuid(),
            HourlyRate = 12,
            Status = SpaceStatus.Occupied,
            Sessions =
            [
                new ParkingSession { Id = sessionId, EndedAt = null },
                new ParkingSession { Id = Guid.NewGuid(), EndedAt = DateTimeOffset.UtcNow }
            ]
        };

        var dto = space.ToDto();

        Assert.Equal(string.Empty, dto.ZoneName);
        Assert.Equal(sessionId, dto.ActiveSessionId);
        Assert.Null(dto.ClientName);
        Assert.NotNull(dto.OccupiedSince);
        Assert.Equal(12, dto.HourlyRate);
    }

    [Fact]
    public void SessionToDto_UsesRelatedNamesAndActiveFlag()
    {
        var started = DateTimeOffset.UtcNow.AddMinutes(-10);
        var session = new ParkingSession
        {
            Id = Guid.NewGuid(),
            SpaceId = Guid.NewGuid(),
            OperatorId = Guid.NewGuid(),
            LicensePlate = "ABC123",
            StartedAt = started,
            Space = new ParkingSpace { Code = "A-01" },
            Operator = new OperatorAccount { Name = "Ana", Username = "ana", Pin = "1234" }
        };

        var dto = session.ToDto();

        Assert.Equal("A-01", dto.SpaceCode);
        Assert.Equal("Ana", dto.OperatorName);
        Assert.True(dto.IsActive);
        Assert.Equal(started, dto.StartedAt);
        Assert.Equal(1, dto.BilledHours);
        Assert.Equal(2, dto.Amount);
        Assert.Equal(2, dto.HourlyRate);
        Assert.False(dto.Paid);
    }

    [Fact]
    public void SessionToDto_UsesPersistedPaymentWhenClosed()
    {
        var started = DateTimeOffset.Parse("2026-09-15T12:00:00Z");
        var ended = started.AddHours(2);
        var session = new ParkingSession
        {
            StartedAt = started,
            EndedAt = ended,
            BilledHours = 2,
            Amount = 4,
            ChargedRate = 2,
            Space = new ParkingSpace { Code = "A-01", HourlyRate = 99 },
            Operator = new OperatorAccount { Name = "Ana", Username = "ana", Pin = "1234" }
        };

        var dto = session.ToDto();

        Assert.False(dto.IsActive);
        Assert.True(dto.Paid);
        Assert.Equal(2, dto.BilledHours);
        Assert.Equal(4, dto.Amount);
        Assert.Equal(2, dto.HourlyRate);
    }
}
