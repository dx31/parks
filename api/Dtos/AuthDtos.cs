namespace Parkimetro.Api.Dtos;

public record LoginRequest(string Username, string Pin);

public record OperatorDto(Guid Id, string Name, string Username);

public record LoginResponse(string Token, OperatorDto Operator);

public record CreateOperatorRequest(string Name, string Username, string Pin);

public record UpdateOperatorRequest(string Name, string Username, string? Pin);
