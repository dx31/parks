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
    }
}
