using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Parkimetro.Api.Data;
using Parkimetro.Api.Dtos;
using Parkimetro.Api.Mapping;

namespace Parkimetro.Api.Controllers;

[ApiController]
[Route("api/reports")]
public class ReportsController(AppDbContext db) : ControllerBase
{
    [HttpGet("earnings")]
    public async Task<ActionResult<EarningsReportDto>> Earnings(
        [FromQuery] DateTimeOffset? from,
        [FromQuery] DateTimeOffset? to)
    {
        var sessions = await db.Sessions
            .Include(session => session.Space)
            .Include(session => session.Operator)
            .Where(session => session.EndedAt != null)
            .ToListAsync();

        if (from is not null)
        {
            sessions = [.. sessions.Where(session => session.EndedAt >= from)];
        }

        if (to is not null)
        {
            sessions = [.. sessions.Where(session => session.EndedAt <= to)];
        }

        sessions = [.. sessions.OrderByDescending(session => session.EndedAt)];

        var payments = sessions
            .Select(session => session.ToDto())
            .ToList();

        var days = payments
            .GroupBy(payment => DateOnly.FromDateTime((payment.EndedAt ?? payment.StartedAt).UtcDateTime.Date))
            .OrderByDescending(group => group.Key)
            .Select(group => new EarningsDayDto(
                group.Key,
                group.Count(),
                group.Sum(item => item.BilledHours),
                group.Sum(item => item.Amount)))
            .ToList();

        return Ok(new EarningsReportDto(
            from,
            to,
            payments.Count,
            payments.Sum(item => item.BilledHours),
            payments.Sum(item => item.Amount),
            days,
            payments));
    }
}
