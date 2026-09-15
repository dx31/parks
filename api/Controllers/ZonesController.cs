using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Parkimetro.Api.Data;
using Parkimetro.Api.Dtos;
using Parkimetro.Api.Mapping;
using Parkimetro.Api.Models;

namespace Parkimetro.Api.Controllers;

[ApiController]
[Route("api/zones")]
public class ZonesController(AppDbContext db) : ControllerBase
{
    [HttpGet]
    public async Task<ActionResult<IEnumerable<ZoneDto>>> GetAll()
    {
        var zones = await db.Zones
            .Include(zone => zone.Spaces)
            .OrderBy(zone => zone.Name)
            .ToListAsync();

        return Ok(zones.Select(zone => zone.ToDto()));
    }

    [HttpGet("{id:guid}")]
    public async Task<ActionResult<ZoneDto>> GetById(Guid id)
    {
        var zone = await db.Zones.Include(item => item.Spaces).FirstOrDefaultAsync(item => item.Id == id);
        return zone is null ? NotFound() : Ok(zone.ToDto());
    }

    [HttpPost]
    public async Task<ActionResult<ZoneDto>> Create([FromBody] CreateZoneRequest request)
    {
        if (string.IsNullOrWhiteSpace(request.Name))
        {
            return BadRequest(new { message = "El nombre de la zona es obligatorio." });
        }

        var zone = new Zone
        {
            Id = Guid.NewGuid(),
            Name = request.Name.Trim(),
            City = string.IsNullOrWhiteSpace(request.City) ? "Ciudad" : request.City.Trim(),
            VideoUrl = NormalizeVideoUrl(request.VideoUrl)
        };

        db.Zones.Add(zone);
        await db.SaveChangesAsync();
        return CreatedAtAction(nameof(GetById), new { id = zone.Id }, zone.ToDto());
    }

    [HttpPut("{id:guid}")]
    public async Task<ActionResult<ZoneDto>> Update(Guid id, [FromBody] UpdateZoneRequest request)
    {
        var zone = await db.Zones.Include(item => item.Spaces).FirstOrDefaultAsync(item => item.Id == id);
        if (zone is null)
        {
            return NotFound();
        }

        if (string.IsNullOrWhiteSpace(request.Name))
        {
            return BadRequest(new { message = "El nombre de la zona es obligatorio." });
        }

        zone.Name = request.Name.Trim();
        zone.City = string.IsNullOrWhiteSpace(request.City) ? zone.City : request.City.Trim();
        zone.VideoUrl = NormalizeVideoUrl(request.VideoUrl);
        await db.SaveChangesAsync();
        return Ok(zone.ToDto());
    }

    private static string? NormalizeVideoUrl(string? value) =>
        string.IsNullOrWhiteSpace(value) ? null : value.Trim();
}
