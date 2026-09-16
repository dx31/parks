using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Parkimetro.Api.Auth;
using Parkimetro.Api.Billing;
using Parkimetro.Api.Data;
using Parkimetro.Api.Dtos;
using Parkimetro.Api.Identity;
using Parkimetro.Api.Mapping;
using Parkimetro.Api.Models;

namespace Parkimetro.Api.Controllers;

[ApiController]
[Route("api/spaces")]
public class SpacesController(AppDbContext db, IRucDirectory directory) : ControllerBase
{
    [HttpGet]
    public async Task<ActionResult<IEnumerable<SpaceDto>>> GetAll(
        [FromQuery] Guid? zoneId,
        [FromQuery] SpaceStatus? status)
    {
        var query = db.Spaces
            .Include(space => space.Zone)
            .Include(space => space.Sessions)
            .AsQueryable();

        if (zoneId is not null)
        {
            query = query.Where(space => space.ZoneId == zoneId);
        }

        if (status is not null)
        {
            query = query.Where(space => space.Status == status);
        }

        var spaces = await query
            .OrderBy(space => space.Zone!.Name)
            .ThenBy(space => space.Code)
            .ToListAsync();

        return Ok(spaces.Select(space => space.ToDto()));
    }

    [HttpGet("{id:guid}")]
    public async Task<ActionResult<SpaceDto>> GetById(Guid id)
    {
        var space = await FindSpaceAsync(id);
        return space is null ? NotFound() : Ok(space.ToDto());
    }

    [HttpPost]
    public async Task<ActionResult<SpaceDto>> Create([FromBody] CreateSpaceRequest request)
    {
        if (string.IsNullOrWhiteSpace(request.Code))
        {
            return BadRequest(new { message = "El código del espacio es obligatorio." });
        }

        var zoneExists = await db.Zones.AnyAsync(zone => zone.Id == request.ZoneId);
        if (!zoneExists)
        {
            return BadRequest(new { message = "La zona no existe." });
        }

        var duplicated = await db.Spaces.AnyAsync(space =>
            space.ZoneId == request.ZoneId && space.Code == request.Code.Trim());
        if (duplicated)
        {
            return Conflict(new { message = "Ya existe un espacio con ese código en la zona." });
        }

        var space = new ParkingSpace
        {
            Id = Guid.NewGuid(),
            Code = request.Code.Trim(),
            ZoneId = request.ZoneId,
            Latitude = request.Latitude,
            Longitude = request.Longitude,
            HourlyRate = request.HourlyRate > 0 ? request.HourlyRate : ParkingBilling.DefaultHourlyRate,
            Notes = request.Notes,
            Status = SpaceStatus.Free,
            UpdatedAt = DateTimeOffset.UtcNow
        };

        db.Spaces.Add(space);
        await db.SaveChangesAsync();

        space = await FindSpaceAsync(space.Id);
        return CreatedAtAction(nameof(GetById), new { id = space!.Id }, space.ToDto());
    }

    [HttpPut("{id:guid}")]
    public async Task<ActionResult<SpaceDto>> Update(Guid id, [FromBody] UpdateSpaceRequest request)
    {
        var space = await FindSpaceAsync(id);
        if (space is null)
        {
            return NotFound();
        }

        space.Code = request.Code.Trim();
        space.Latitude = request.Latitude;
        space.Longitude = request.Longitude;
        space.HourlyRate = request.HourlyRate > 0 ? request.HourlyRate : ParkingBilling.DefaultHourlyRate;
        space.Notes = request.Notes;
        space.UpdatedAt = DateTimeOffset.UtcNow;
        await db.SaveChangesAsync();
        return Ok(space.ToDto());
    }

    [HttpPatch("{id:guid}/status")]
    public async Task<ActionResult<SpaceDto>> ChangeStatus(Guid id, [FromBody] ChangeStatusRequest request)
    {
        var space = await FindSpaceAsync(id);
        if (space is null)
        {
            return NotFound();
        }

        if (request.Status == SpaceStatus.Reserved)
        {
            return await ReserveCore(space, request.Dni, request.ClientName);
        }

        if (request.Status == SpaceStatus.Occupied && !space.Sessions.Any(item => item.EndedAt is null))
        {
            db.Sessions.Add(new ParkingSession
            {
                Id = Guid.NewGuid(),
                SpaceId = space.Id,
                OperatorId = HttpContext.GetOperatorId(),
                StartedAt = DateTimeOffset.UtcNow
            });
        }

        if (request.Status == SpaceStatus.Free)
        {
            var endedAt = DateTimeOffset.UtcNow;
            foreach (var session in space.Sessions.Where(item => item.EndedAt is null))
            {
                ParkingSettlement.Close(session, space, endedAt);
            }
        }

        if (request.Status is SpaceStatus.Free or SpaceStatus.OutOfService)
        {
            ClearClient(space);
        }

        space.Status = request.Status;
        space.UpdatedAt = DateTimeOffset.UtcNow;
        await db.SaveChangesAsync();
        space = await FindSpaceAsync(id);
        return Ok(space!.ToDto());
    }

    [HttpPost("{id:guid}/reserve")]
    public async Task<ActionResult<SpaceDto>> Reserve(Guid id, [FromBody] ReserveSpaceRequest request)
    {
        var space = await FindSpaceAsync(id);
        if (space is null)
        {
            return NotFound();
        }

        return await ReserveCore(space, request.Dni, request.ClientName);
    }

    [HttpDelete("{id:guid}")]
    public async Task<IActionResult> Delete(Guid id)
    {
        var space = await FindSpaceAsync(id);
        if (space is null)
        {
            return NotFound();
        }

        db.Sessions.RemoveRange(space.Sessions);
        db.Spaces.Remove(space);
        await db.SaveChangesAsync();
        return NoContent();
    }

    private async Task<ActionResult<SpaceDto>> ReserveCore(ParkingSpace space, string? dni, string? clientName)
    {
        if (space.Status == SpaceStatus.OutOfService)
        {
            return BadRequest(new { message = "El espacio está fuera de servicio." });
        }

        if (space.Sessions.Any(session => session.EndedAt is null))
        {
            return Conflict(new { message = "Ese espacio ya tiene una sesión activa." });
        }

        var normalizedDni = DniRuc.NormalizeDni(dni);
        if (normalizedDni is null)
        {
            return BadRequest(new { message = "Indica el DNI de 8 dígitos del cliente." });
        }

        ClientIdentity? found = null;
        try
        {
            found = await directory.FindByDniAsync(normalizedDni);
        }
        catch (InvalidOperationException exception)
        {
            if (string.IsNullOrWhiteSpace(clientName))
            {
                return StatusCode(StatusCodes.Status503ServiceUnavailable, new { message = exception.Message });
            }
        }

        var name = string.IsNullOrWhiteSpace(found?.Name) ? clientName?.Trim() : found!.Name;
        if (string.IsNullOrWhiteSpace(name))
        {
            return BadRequest(new { message = "No se encontró el nombre. Ingrésalo manualmente." });
        }

        space.Status = SpaceStatus.Reserved;
        space.ClientDni = normalizedDni;
        space.ClientRuc = found?.Ruc ?? DniRuc.ToRuc(normalizedDni);
        space.ClientName = name;
        space.UpdatedAt = DateTimeOffset.UtcNow;
        await db.SaveChangesAsync();
        return Ok(space.ToDto());
    }

    private static void ClearClient(ParkingSpace space)
    {
        space.ClientDni = null;
        space.ClientRuc = null;
        space.ClientName = null;
    }

    private Task<ParkingSpace?> FindSpaceAsync(Guid id) =>
        db.Spaces
            .Include(space => space.Zone)
            .Include(space => space.Sessions)
            .FirstOrDefaultAsync(space => space.Id == id);
}
