using Parkimetro.Api.Auth;

namespace Parkimetro.Api.Tests.Unit;

public class OperatorSessionStoreTests
{
    [Fact]
    public void Issue_ThenResolve_ReturnsSameOperator()
    {
        var store = new OperatorSessionStore();
        var operatorId = Guid.NewGuid();

        var token = store.Issue(operatorId);

        Assert.True(store.TryGetOperatorId(token, out var resolved));
        Assert.Equal(operatorId, resolved);
    }

    [Theory]
    [InlineData(null)]
    [InlineData("")]
    [InlineData("   ")]
    [InlineData("unknown")]
    public void TryGetOperatorId_WithInvalidToken_ReturnsFalse(string? token)
    {
        var store = new OperatorSessionStore();

        Assert.False(store.TryGetOperatorId(token, out var operatorId));
        Assert.Equal(Guid.Empty, operatorId);
    }
}
