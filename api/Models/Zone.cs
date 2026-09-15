namespace Parkimetro.Api.Models;

public class Zone
{
    public Guid Id { get; set; }
    public required string Name { get; set; }
    public required string City { get; set; }
    public string? VideoUrl { get; set; }
    public ICollection<ParkingSpace> Spaces { get; set; } = [];
}
