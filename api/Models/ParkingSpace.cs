namespace Parkimetro.Api.Models;

public class ParkingSpace
{
    public Guid Id { get; set; }
    public required string Code { get; set; }
    public Guid ZoneId { get; set; }
    public Zone? Zone { get; set; }
    public double Latitude { get; set; }
    public double Longitude { get; set; }
    public decimal HourlyRate { get; set; }
    public SpaceStatus Status { get; set; } = SpaceStatus.Free;
    public string? Notes { get; set; }
    public string? ClientDni { get; set; }
    public string? ClientRuc { get; set; }
    public string? ClientName { get; set; }
    public string? LicensePlate { get; set; }
    public DateTimeOffset? ReservedFrom { get; set; }
    public DateTimeOffset? LimitUntil { get; set; }
    public DateTimeOffset UpdatedAt { get; set; } = DateTimeOffset.UtcNow;
    public ICollection<ParkingSession> Sessions { get; set; } = [];
}
