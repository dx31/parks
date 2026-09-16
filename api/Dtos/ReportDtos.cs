namespace Parkimetro.Api.Dtos;

public record EarningsDayDto(DateOnly Date, int PaymentsCount, int Hours, decimal Amount);

public record EarningsReportDto(
    DateTimeOffset? From,
    DateTimeOffset? To,
    int PaymentsCount,
    int TotalHours,
    decimal TotalAmount,
    IReadOnlyList<EarningsDayDto> Days,
    IReadOnlyList<SessionDto> Payments);
