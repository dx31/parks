using Microsoft.AspNetCore.Mvc;
using Parkimetro.Api.Dtos;
using Parkimetro.Api.Identity;
using Parkimetro.Api.Mapping;

namespace Parkimetro.Api.Controllers;

[ApiController]
[Route("api/clients")]
public class ClientsController(IRucDirectory directory) : ControllerBase
{
    [HttpGet("{dni}")]
    public async Task<ActionResult<ClientIdentityDto>> GetByDni(string dni, CancellationToken cancellationToken)
    {
        if (DniRuc.NormalizeDni(dni) is null)
        {
            return BadRequest(new { message = "El DNI debe tener 8 dígitos." });
        }

        try
        {
            var identity = await directory.FindByDniAsync(dni, cancellationToken);
            return identity is null
                ? NotFound(new { message = "No se encontró el DNI en el padrón RUC." })
                : Ok(identity.ToDto());
        }
        catch (InvalidOperationException exception)
        {
            return StatusCode(StatusCodes.Status503ServiceUnavailable, new { message = exception.Message });
        }
    }
}
