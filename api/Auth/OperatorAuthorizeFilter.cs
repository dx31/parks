using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.Filters;

namespace Parkimetro.Api.Auth;

public sealed class OperatorAuthorizeFilter(OperatorSessionStore sessions) : IAsyncActionFilter
{
    public const string OperatorIdItem = "OperatorId";

    public async Task OnActionExecutionAsync(ActionExecutingContext context, ActionExecutionDelegate next)
    {
        if (context.ActionDescriptor.EndpointMetadata.OfType<IAllowAnonymous>().Any())
        {
            await next();
            return;
        }

        var header = context.HttpContext.Request.Headers.Authorization.ToString();
        var token = ReadBearerToken(header);
        if (!sessions.TryGetOperatorId(token, out var operatorId))
        {
            context.Result = new UnauthorizedObjectResult(new { message = "Inicia sesión como operador." });
            return;
        }

        context.HttpContext.Items[OperatorIdItem] = operatorId;
        await next();
    }

    public static string? ReadBearerToken(string? header)
    {
        if (string.IsNullOrWhiteSpace(header))
        {
            return null;
        }

        return header.StartsWith("Bearer ", StringComparison.OrdinalIgnoreCase)
            ? header["Bearer ".Length..]
            : header;
    }
}

public static class OperatorAuthExtensions
{
    public static Guid GetOperatorId(this HttpContext context)
    {
        if (context.Items.TryGetValue(OperatorAuthorizeFilter.OperatorIdItem, out var value) && value is Guid operatorId)
        {
            return operatorId;
        }

        throw new InvalidOperationException("No hay operador autenticado.");
    }
}
