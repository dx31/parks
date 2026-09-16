using Microsoft.AspNetCore.Http;
using Parkimetro.Api.Auth;

namespace Parkimetro.Api.Tests.Unit;

public class OperatorAuthorizeFilterTests
{
    [Theory]
    [InlineData("Bearer abc", "abc")]
    [InlineData("bearer abc", "abc")]
    [InlineData("abc", "abc")]
    [InlineData(" ", null)]
    [InlineData(null, null)]
    public void ReadBearerToken_NormalizesHeader(string? header, string? expected)
    {
        Assert.Equal(expected, OperatorAuthorizeFilter.ReadBearerToken(header));
    }

    [Fact]
    public void GetOperatorId_WhenMissing_Throws()
    {
        Assert.Throws<InvalidOperationException>(() => new DefaultHttpContext().GetOperatorId());
    }

    [Fact]
    public void GetOperatorId_WhenPresent_ReturnsId()
    {
        var context = new DefaultHttpContext();
        var operatorId = Guid.NewGuid();
        context.Items[OperatorAuthorizeFilter.OperatorIdItem] = operatorId;
        Assert.Equal(operatorId, context.GetOperatorId());
    }
}
