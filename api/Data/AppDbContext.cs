using Microsoft.EntityFrameworkCore;
using Parkimetro.Api.Models;

namespace Parkimetro.Api.Data;

public class AppDbContext(DbContextOptions<AppDbContext> options) : DbContext(options)
{
    public DbSet<Zone> Zones => Set<Zone>();
    public DbSet<ParkingSpace> Spaces => Set<ParkingSpace>();
    public DbSet<ParkingSession> Sessions => Set<ParkingSession>();
    public DbSet<OperatorAccount> Operators => Set<OperatorAccount>();

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        modelBuilder.Entity<Zone>()
            .HasMany(zone => zone.Spaces)
            .WithOne(space => space.Zone)
            .HasForeignKey(space => space.ZoneId);

        modelBuilder.Entity<ParkingSpace>()
            .HasIndex(space => new { space.ZoneId, space.Code })
            .IsUnique();

        modelBuilder.Entity<ParkingSession>()
            .HasOne(session => session.Space)
            .WithMany(space => space.Sessions)
            .HasForeignKey(session => session.SpaceId);

        modelBuilder.Entity<ParkingSession>()
            .HasOne(session => session.Operator)
            .WithMany()
            .HasForeignKey(session => session.OperatorId);

        modelBuilder.Entity<OperatorAccount>()
            .HasIndex(account => account.Username)
            .IsUnique();
    }
}
