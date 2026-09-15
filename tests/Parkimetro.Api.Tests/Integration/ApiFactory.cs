using Microsoft.AspNetCore.Hosting;
using Microsoft.AspNetCore.Mvc.Testing;
using Microsoft.AspNetCore.TestHost;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Infrastructure;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.DependencyInjection.Extensions;
using Parkimetro.Api.Data;
using Parkimetro.Api.Identity;

namespace Parkimetro.Api.Tests.Integration;

public class ApiFactory : WebApplicationFactory<Program>
{
    protected override void ConfigureWebHost(IWebHostBuilder builder)
    {
        builder.UseEnvironment("Testing");
        builder.ConfigureServices(services =>
        {
            foreach (var descriptor in services
                         .Where(service =>
                             service.ServiceType == typeof(AppDbContext)
                             || service.ServiceType == typeof(DbContextOptions)
                             || service.ServiceType == typeof(DbContextOptions<AppDbContext>)
                             || service.ServiceType == typeof(IDbContextOptionsConfiguration<AppDbContext>))
                         .ToList())
            {
                services.Remove(descriptor);
            }

            var databasePath = Path.Combine(Path.GetTempPath(), $"parkimetro-tests-{Guid.NewGuid():N}.db");
            services.AddDbContext<AppDbContext>(options =>
                options.UseSqlite($"Data Source={databasePath}"));
        });
        builder.ConfigureTestServices(services =>
        {
            services.RemoveAll<IRucDirectory>();
            services.AddSingleton<IRucDirectory, InMemoryRucDirectory>();
        });
    }
}

public class ProductionApiFactory : ApiFactory
{
    protected override void ConfigureWebHost(IWebHostBuilder builder)
    {
        base.ConfigureWebHost(builder);
        builder.UseEnvironment("Production");
    }
}
