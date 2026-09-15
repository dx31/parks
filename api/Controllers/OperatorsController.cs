using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Parkimetro.Api.Data;
using Parkimetro.Api.Dtos;
using Parkimetro.Api.Models;

namespace Parkimetro.Api.Controllers;

[ApiController]
[Route("api/operators")]
public class OperatorsController(AppDbContext db) : ControllerBase
{
    [HttpGet]
    public async Task<ActionResult<IEnumerable<OperatorDto>>> GetAll()
    {
        var operators = await db.Operators
            .OrderBy(account => account.Name)
            .Select(account => new OperatorDto(account.Id, account.Name, account.Username))
            .ToListAsync();

        return Ok(operators);
    }

    [HttpGet("{id:guid}")]
    public async Task<ActionResult<OperatorDto>> GetById(Guid id)
    {
        var account = await db.Operators.FirstOrDefaultAsync(item => item.Id == id);
        return account is null
            ? NotFound()
            : Ok(new OperatorDto(account.Id, account.Name, account.Username));
    }

    [HttpPost]
    public async Task<ActionResult<OperatorDto>> Create([FromBody] CreateOperatorRequest request)
    {
        var error = Validate(request.Name, request.Username, request.Pin, pinRequired: true);
        if (error is not null)
        {
            return BadRequest(new { message = error });
        }

        var username = request.Username.Trim().ToLowerInvariant();
        if (await db.Operators.AnyAsync(account => account.Username == username))
        {
            return Conflict(new { message = "Ya existe un usuario con ese nombre." });
        }

        var account = new OperatorAccount
        {
            Id = Guid.NewGuid(),
            Name = request.Name.Trim(),
            Username = username,
            Pin = request.Pin.Trim()
        };

        db.Operators.Add(account);
        await db.SaveChangesAsync();
        return CreatedAtAction(
            nameof(GetById),
            new { id = account.Id },
            new OperatorDto(account.Id, account.Name, account.Username));
    }

    [HttpPut("{id:guid}")]
    public async Task<ActionResult<OperatorDto>> Update(Guid id, [FromBody] UpdateOperatorRequest request)
    {
        var account = await db.Operators.FirstOrDefaultAsync(item => item.Id == id);
        if (account is null)
        {
            return NotFound();
        }

        var pinRequired = !string.IsNullOrWhiteSpace(request.Pin);
        var error = Validate(request.Name, request.Username, request.Pin, pinRequired);
        if (error is not null)
        {
            return BadRequest(new { message = error });
        }

        var username = request.Username.Trim().ToLowerInvariant();
        if (await db.Operators.AnyAsync(item => item.Username == username && item.Id != id))
        {
            return Conflict(new { message = "Ya existe un usuario con ese nombre." });
        }

        account.Name = request.Name.Trim();
        account.Username = username;
        if (pinRequired)
        {
            account.Pin = request.Pin!.Trim();
        }

        await db.SaveChangesAsync();
        return Ok(new OperatorDto(account.Id, account.Name, account.Username));
    }

    [HttpDelete("{id:guid}")]
    public async Task<IActionResult> Delete(Guid id)
    {
        var account = await db.Operators.FirstOrDefaultAsync(item => item.Id == id);
        if (account is null)
        {
            return NotFound();
        }

        if (await db.Operators.CountAsync() <= 1)
        {
            return BadRequest(new { message = "No se puede eliminar el último usuario." });
        }

        if (await db.Sessions.AnyAsync(session => session.OperatorId == id))
        {
            return Conflict(new { message = "Ese usuario tiene sesiones registradas." });
        }

        db.Operators.Remove(account);
        await db.SaveChangesAsync();
        return NoContent();
    }

    private static string? Validate(string? name, string? username, string? pin, bool pinRequired)
    {
        if (string.IsNullOrWhiteSpace(name))
        {
            return "El nombre es obligatorio.";
        }

        if (string.IsNullOrWhiteSpace(username))
        {
            return "El usuario es obligatorio.";
        }

        if (pinRequired && (string.IsNullOrWhiteSpace(pin) || pin.Trim().Length < 4))
        {
            return "El PIN debe tener al menos 4 caracteres.";
        }

        return null;
    }
}
