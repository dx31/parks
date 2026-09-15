namespace Parkimetro.Api.Models;

public class OperatorAccount
{
    public Guid Id { get; set; }
    public required string Name { get; set; }
    public required string Username { get; set; }
    public required string Pin { get; set; }
}
