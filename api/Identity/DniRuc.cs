namespace Parkimetro.Api.Identity;

public static class DniRuc
{
    public static string? NormalizeDni(string? value)
    {
        if (string.IsNullOrWhiteSpace(value))
        {
            return null;
        }

        var digits = new string(value.Where(char.IsDigit).ToArray());
        return digits.Length == 8 ? digits : null;
    }

    public static string ToRuc(string dni)
    {
        var normalized = NormalizeDni(dni)
            ?? throw new ArgumentException("El DNI debe tener 8 dígitos.", nameof(dni));

        var body = "10" + normalized;
        int[] weights = [5, 4, 3, 2, 7, 6, 5, 4, 3, 2];
        var sum = 0;
        for (var i = 0; i < 10; i++)
        {
            sum += (body[i] - '0') * weights[i];
        }

        var check = 11 - (sum % 11);
        if (check >= 10)
        {
            check = 11 - check;
        }

        return body + check;
    }
}
