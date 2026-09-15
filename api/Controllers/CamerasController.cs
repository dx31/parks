using Microsoft.AspNetCore.Mvc;

namespace Parkimetro.Api.Controllers;

[ApiController]
[Route("api/cameras")]
public class CamerasController(IWebHostEnvironment environment) : ControllerBase
{
    [HttpGet("{name}")]
    public IActionResult Get(string name)
    {
        if (!IsSafeName(name))
        {
            return BadRequest(new { message = "Nombre de cámara inválido." });
        }

        var path = ResolveVideoPath(name);
        if (path is null)
        {
            return NotFound(new { message = "No hay video para esa cámara." });
        }

        Response.Headers.CacheControl = "no-cache, no-store";
        return PhysicalFile(path, "video/mp4", enableRangeProcessing: true);
    }

    private string? ResolveVideoPath(string name)
    {
        var fileName = name + ".mp4";
        var candidates = new[]
        {
            Path.Combine(environment.ContentRootPath, "Media", fileName),
            Path.Combine(AppContext.BaseDirectory, "Media", fileName)
        };

        return candidates.FirstOrDefault(System.IO.File.Exists);
    }

    private static bool IsSafeName(string name) =>
        name.Length is > 0 and <= 64 && name.All(character => char.IsAsciiLetterOrDigit(character) || character is '-' or '_');
}
