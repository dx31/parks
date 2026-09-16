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
    bool IsActive,
    int BilledHours,
    decimal Amount,
    decimal HourlyRate,
    bool Paid);

public record StartSessionRequest(Guid SpaceId, string? LicensePlate);
