using Microsoft.EntityFrameworkCore;
using Parkimetro.Api.Billing;
using Parkimetro.Api.Models;

namespace Parkimetro.Api.Data;

public static class DbSeeder
{
    public static async Task SeedAsync(AppDbContext db)
    {
        if (await db.Zones.AnyAsync())
        {
            await AssignDemoCameraAsync(db);
            await AlignRatesAsync(db);
            return;
        }

        var centro = new Zone
        {
            Id = Guid.Parse("11111111-1111-1111-1111-111111111111"),
            Name = "Centro Histórico",
            City = "Ciudad",
            VideoUrl = "/api/cameras/demo"
        };
        var universidad = new Zone
        {
            Id = Guid.Parse("22222222-2222-2222-2222-222222222222"),
            Name = "Zona Universitaria",
            City = "Ciudad",
            VideoUrl = "/api/cameras/demo"
        };

        var spaces = new List<ParkingSpace>
        {
            Space(centro.Id, "A-01", 19.43260, -99.13320, ParkingBilling.DefaultHourlyRate, SpaceStatus.Free),
            Space(centro.Id, "A-02", 19.43272, -99.13305, ParkingBilling.DefaultHourlyRate, SpaceStatus.Occupied),
            Space(centro.Id, "A-03", 19.43285, -99.13290, ParkingBilling.DefaultHourlyRate, SpaceStatus.Free),
            Space(universidad.Id, "B-01", 19.33180, -99.18440, ParkingBilling.DefaultHourlyRate, SpaceStatus.Free),
            Space(universidad.Id, "B-02", 19.33195, -99.18420, ParkingBilling.DefaultHourlyRate, SpaceStatus.Reserved),
            Space(universidad.Id, "B-03", 19.33210, -99.18400, ParkingBilling.DefaultHourlyRate, SpaceStatus.OutOfService)
        };

        var occupied = spaces[1];
        db.Zones.AddRange(centro, universidad);
        db.Spaces.AddRange(spaces);
        var ana = new OperatorAccount
        {
            Id = Guid.Parse("33333333-3333-3333-3333-333333333333"),
            Name = "Ana López",
            Username = "ana",
            Pin = "1234"
        };
        db.Operators.Add(ana);
        db.Sessions.Add(new ParkingSession
        {
            Id = Guid.NewGuid(),
            SpaceId = occupied.Id,
            OperatorId = ana.Id,
            StartedAt = DateTimeOffset.UtcNow.AddMinutes(-8)
        });

        await db.SaveChangesAsync();
        await AlignRatesAsync(db);
    }

    private static async Task AlignRatesAsync(AppDbContext db)
    {
        var spaces = await db.Spaces.ToListAsync();
        foreach (var space in spaces.Where(item => item.HourlyRate != ParkingBilling.DefaultHourlyRate))
        {
            space.HourlyRate = ParkingBilling.DefaultHourlyRate;
        }

        if (spaces.Count > 0)
        {
            await db.SaveChangesAsync();
        }
    }

    private static async Task AssignDemoCameraAsync(AppDbContext db)
    {
        var seeded = await db.Zones
            .Where(zone =>
                zone.Id == Guid.Parse("11111111-1111-1111-1111-111111111111")
                || zone.Id == Guid.Parse("22222222-2222-2222-2222-222222222222"))
            .ToListAsync();

        foreach (var zone in seeded.Where(zone => string.IsNullOrWhiteSpace(zone.VideoUrl)))
        {
            zone.VideoUrl = "/api/cameras/demo";
        }

        if (seeded.Count > 0)
        {
            await db.SaveChangesAsync();
        }
    }

    private static ParkingSpace Space(
        Guid zoneId,
        string code,
        double latitude,
        double longitude,
        decimal hourlyRate,
        SpaceStatus status) =>
        new()
        {
            Id = Guid.NewGuid(),
            ZoneId = zoneId,
            Code = code,
            Latitude = latitude,
            Longitude = longitude,
            HourlyRate = hourlyRate,
            Status = status,
            UpdatedAt = DateTimeOffset.UtcNow
        };
}
