using System.Collections.Concurrent;

namespace Parkimetro.Api.Auth;

public class OperatorSessionStore
{
    private readonly ConcurrentDictionary<string, Guid> _tokens = new();

    public string Issue(Guid operatorId)
    {
        var token = Guid.NewGuid().ToString("N");
        _tokens[token] = operatorId;
        return token;
    }

    public bool TryGetOperatorId(string? token, out Guid operatorId)
    {
        operatorId = Guid.Empty;
        return !string.IsNullOrWhiteSpace(token) && _tokens.TryGetValue(token, out operatorId);
    }
}
