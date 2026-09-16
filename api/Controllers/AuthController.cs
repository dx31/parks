using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Parkimetro.Api.Auth;
using Parkimetro.Api.Data;
using Parkimetro.Api.Dtos;

namespace Parkimetro.Api.Controllers;

[ApiController]
[Route("api/auth")]
public class AuthController(AppDbContext db, OperatorSessionStore sessions) : ControllerBase
{
    [AllowAnonymous]
    [HttpPost("login")]
    public async Task<ActionResult<LoginResponse>> Login([FromBody] LoginRequest request)
    {
        var account = await db.Operators.FirstOrDefaultAsync(operatorAccount =>
            operatorAccount.Username == request.Username && operatorAccount.Pin == request.Pin);

        if (account is null)
        {
            return Unauthorized(new { message = "Usuario o PIN incorrectos." });
        }

        var token = sessions.Issue(account.Id);
        return Ok(new LoginResponse(token, new OperatorDto(account.Id, account.Name, account.Username)));
    }
}
