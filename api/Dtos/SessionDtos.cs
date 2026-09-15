namespace Parkimetro.Api.Dtos;

public record SessionDto(
    Guid Id,
    Guid SpaceId,
    string SpaceCode,
    Guid OperatorId,
    string OperatorName,
    string? LicensePlate,
    DateTimeOffset StartedAt,
    DateTimeOffset? EndedAt,
    bool IsActive);

public record StartSessionRequest(Guid SpaceId, string? LicensePlate);
