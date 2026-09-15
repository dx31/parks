using Parkimetro.Api.Identity;

namespace Parkimetro.Api.Tests.Unit;

public class DniRucTests
{
    [Theory]
    [InlineData("12345678", "12345678")]
    [InlineData(" 12.345.678 ", "12345678")]
    [InlineData("1234", null)]
    [InlineData("", null)]
    [InlineData(null, null)]
    public void NormalizeDni_KeepsEightDigits(string? value, string? expected)
    {
        Assert.Equal(expected, DniRuc.NormalizeDni(value));
    }

    [Fact]
    public void ToRuc_Prefixes10AndVerificationDigit()
    {
        Assert.Equal("10123456780", DniRuc.ToRuc("12345678"));
        Assert.Equal("10000000065", DniRuc.ToRuc("00000006"));
    }

    [Fact]
    public void ToRuc_WhenInvalid_Throws()
    {
        Assert.Throws<ArgumentException>(() => DniRuc.ToRuc("123"));
    }
}
