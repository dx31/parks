using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Parkimetro.Api.Auth;
using Parkimetro.Api.Billing;
using Parkimetro.Api.Data;
using Parkimetro.Api.Dtos;
using Parkimetro.Api.Identity;
using Parkimetro.Api.Mapping;
using Parkimetro.Api.Models;
using Parkimetro.Api.Parking;

namespace Parkimetro.Api.Controllers;

[ApiController]
[Route("api/sessions")]
public class SessionsController(AppDbContext db, IRucDirectory directory) : ControllerBase
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
        var operatorId = HttpContext.GetOperatorId();
        var space = await db.Spaces
            .Include(item => item.Sessions)
            .FirstOrDefaultAsync(item => item.Id == request.SpaceId);

        if (space is null)
        {
            return NotFound(new { message = "El espacio no existe." });
        }

        var started = await ParkingOccupation.StartAsync(
            directory,
            space,
            operatorId,
            request.Dni,
            request.ClientName,
            request.LicensePlate,
            request.LimitUntil);

        if (!started.Succeeded)
        {
            return StatusCode(started.StatusCode, new { message = started.Message });
        }

        db.Sessions.Add(started.Session!);
        await db.SaveChangesAsync();

        var session = await db.Sessions
            .Include(item => item.Space)
            .Include(item => item.Operator)
            .FirstAsync(item => item.Id == started.Session!.Id);

        return CreatedAtAction(nameof(GetAll), session.ToDto());
    }

    [HttpPost("{id:guid}/end")]
    public async Task<ActionResult<SessionDto>> End(Guid id)
    {
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

        ParkingSettlement.Close(session, session.Space, DateTimeOffset.UtcNow);
        if (session.Space is not null)
        {
            session.Space.Status = SpaceStatus.Free;
            session.Space.UpdatedAt = DateTimeOffset.UtcNow;
            ParkingStay.Clear(session.Space);
        }

        await db.SaveChangesAsync();
        return Ok(session.ToDto());
    }
}
