namespace Parkimetro.Api.Models;

public class ParkingSession
{
    public Guid Id { get; set; }
    public Guid SpaceId { get; set; }
    public ParkingSpace? Space { get; set; }
    public Guid OperatorId { get; set; }
    public OperatorAccount? Operator { get; set; }
    public string? LicensePlate { get; set; }
    public DateTimeOffset StartedAt { get; set; } = DateTimeOffset.UtcNow;
    public DateTimeOffset? LimitUntil { get; set; }
    public DateTimeOffset? EndedAt { get; set; }
    public int? BilledHours { get; set; }
    public decimal? Amount { get; set; }
    public decimal? ChargedRate { get; set; }

    public bool IsActive => EndedAt is null;
}
