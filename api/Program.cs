using System.Text.Json;
using System.Text.Json.Serialization;
using Microsoft.EntityFrameworkCore;
using Parkimetro.Api.Auth;
using Parkimetro.Api.Data;
using Parkimetro.Api.Identity;

var builder = WebApplication.CreateBuilder(args);

builder.Services.AddControllers()
    .AddJsonOptions(options =>
    {
        options.JsonSerializerOptions.PropertyNamingPolicy = JsonNamingPolicy.CamelCase;
        options.JsonSerializerOptions.Converters.Add(
            new JsonStringEnumConverter(JsonNamingPolicy.CamelCase));
    });
builder.Services.AddOpenApi(options =>
{
    options.AddDocumentTransformer((document, _, _) =>
    {
        document.Info.Title = "Parkímetro API";
        document.Info.Version = "v1";
        document.Info.Description = "API para operadores y clientes de parquímetros.";
        return Task.CompletedTask;
    });
});
builder.Services.AddSingleton<OperatorSessionStore>();
builder.Services.Configure<RucDirectoryOptions>(
    builder.Configuration.GetSection(RucDirectoryOptions.SectionName));
builder.Services.AddSingleton<IRucDirectory, MariaDbRucDirectory>();

builder.Services.AddDbContext<AppDbContext>(options =>
    options.UseSqlite(builder.Configuration.GetConnectionString("Default") ?? "Data Source=parkimetro.db"));
builder.Services.AddCors(options =>
    options.AddDefaultPolicy(policy =>
        policy.AllowAnyOrigin().AllowAnyHeader().AllowAnyMethod()));

var app = builder.Build();

using (var scope = app.Services.CreateScope())
{
    var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();
    await db.Database.EnsureCreatedAsync();
    await SchemaPatcher.ApplyAsync(db);
    await DbSeeder.SeedAsync(db);
}

if (!app.Environment.IsProduction())
{
    app.MapOpenApi();
    app.UseSwaggerUI(options =>
    {
        options.SwaggerEndpoint("/openapi/v1.json", "Parkímetro API v1");
        options.RoutePrefix = "swagger";
    });
}

app.UseCors();
app.MapControllers();
app.Run();

public partial class Program;
