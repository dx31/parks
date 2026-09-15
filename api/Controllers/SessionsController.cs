using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Parkimetro.Api.Auth;
using Parkimetro.Api.Data;
using Parkimetro.Api.Dtos;
using Parkimetro.Api.Mapping;
using Parkimetro.Api.Models;

namespace Parkimetro.Api.Controllers;

[ApiController]
[Route("api/sessions")]
public class SessionsController(AppDbContext db, OperatorSessionStore sessions) : ControllerBase
{
    [HttpGet]
    public async Task<ActionResult<IEnumerable<SessionDto>>> GetAll([FromQuery] bool activeOnly = false)
    {
        var query = db.Sessions
            .Include(session => session.Space)
            .Include(session => session.Operator)
            .AsQueryable();

        if (activeOnly)
        {
            query = query.Where(session => session.EndedAt == null);
        }

        var items = await query.ToListAsync();
        items = [.. items.OrderByDescending(session => session.StartedAt)];

        return Ok(items.Select(session => session.ToDto()));
    }

    [HttpPost]
    public async Task<ActionResult<SessionDto>> Start([FromBody] StartSessionRequest request)
    {
        if (!TryGetOperatorId(out var operatorId))
        {
            return Unauthorized(new { message = "Inicia sesión como operador." });
        }

        var space = await db.Spaces
            .Include(item => item.Sessions)
            .FirstOrDefaultAsync(item => item.Id == request.SpaceId);

        if (space is null)
        {
            return NotFound(new { message = "El espacio no existe." });
        }

        if (space.Status == SpaceStatus.OutOfService)
        {
            return BadRequest(new { message = "El espacio está fuera de servicio." });
        }

        if (space.Sessions.Any(session => session.EndedAt is null))
        {
            return Conflict(new { message = "Ese espacio ya tiene una sesión activa." });
        }

        var session = new ParkingSession
        {
            Id = Guid.NewGuid(),
            SpaceId = space.Id,
            OperatorId = operatorId,
            LicensePlate = string.IsNullOrWhiteSpace(request.LicensePlate) ? null : request.LicensePlate.Trim().ToUpperInvariant(),
            StartedAt = DateTimeOffset.UtcNow
        };

        space.Status = SpaceStatus.Occupied;
        space.UpdatedAt = DateTimeOffset.UtcNow;
        db.Sessions.Add(session);
        await db.SaveChangesAsync();

        session = await db.Sessions
            .Include(item => item.Space)
            .Include(item => item.Operator)
            .FirstAsync(item => item.Id == session.Id);

        return CreatedAtAction(nameof(GetAll), session.ToDto());
    }

    [HttpPost("{id:guid}/end")]
    public async Task<ActionResult<SessionDto>> End(Guid id)
    {
        if (!TryGetOperatorId(out _))
        {
            return Unauthorized(new { message = "Inicia sesión como operador." });
        }

        var session = await db.Sessions
            .Include(item => item.Space)
            .Include(item => item.Operator)
            .FirstOrDefaultAsync(item => item.Id == id);

        if (session is null)
        {
            return NotFound();
        }

        if (session.EndedAt is not null)
        {
            return BadRequest(new { message = "La sesión ya estaba cerrada." });
        }

        session.EndedAt = DateTimeOffset.UtcNow;
        if (session.Space is not null)
        {
            session.Space.Status = SpaceStatus.Free;
            session.Space.UpdatedAt = DateTimeOffset.UtcNow;
        }

        await db.SaveChangesAsync();
        return Ok(session.ToDto());
    }

    private bool TryGetOperatorId(out Guid operatorId)
    {
        var header = Request.Headers.Authorization.ToString();
        var token = header.StartsWith("Bearer ", StringComparison.OrdinalIgnoreCase)
            ? header["Bearer ".Length..]
            : header;
        return sessions.TryGetOperatorId(token, out operatorId);
    }
}
