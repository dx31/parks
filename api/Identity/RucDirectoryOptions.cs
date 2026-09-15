namespace Parkimetro.Api.Identity;

public class RucDirectoryOptions
{
    public const string SectionName = "RucDirectory";

    public string ConnectionString { get; set; } =
        "Server=127.0.0.1;Port=3306;Database=ruc;User=ruc;Password=ruc;";

    public string Table { get; set; } = "t";

    public string RucColumn { get; set; } = "ruc";

    public string NameColumn { get; set; } = "nombres_razon_social";

    public string? AddressColumn { get; set; } = "direccion";
}
