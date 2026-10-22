using Microsoft.AspNetCore.Identity;
using Microsoft.EntityFrameworkCore;
using MunicipalElections.Api.Models;

namespace MunicipalElections.Api.Data;

public static class DbInitializer
{
    /// <summary>
    /// Applies EF Core migrations on startup (so a fresh Azure deployment creates its own database),
    /// then creates an optional demo account for testing/marking.
    /// </summary>
    public static async Task InitializeAsync(IServiceProvider services)
    {
        using var scope = services.CreateScope();
        var sp = scope.ServiceProvider;
        var db = sp.GetRequiredService<AppDbContext>();
        var logger = sp.GetRequiredService<ILoggerFactory>().CreateLogger("DbInitializer");

        if (db.Database.GetMigrations().Any())
        {
            await db.Database.MigrateAsync();
        }
        else
        {
            // Fallback if no migration has been generated yet. Run
            // `dotnet ef migrations add InitialCreate` to use proper code-first migrations.
            logger.LogWarning("No EF Core migrations found; creating the database with EnsureCreated.");
            await db.Database.EnsureCreatedAsync();
        }

        var config = sp.GetRequiredService<IConfiguration>();
        var demoEmail = config["DemoUser:Email"];
        var demoPassword = config["DemoUser:Password"];
        if (string.IsNullOrWhiteSpace(demoEmail) || string.IsNullOrWhiteSpace(demoPassword))
        {
            return;
        }

        var userManager = sp.GetRequiredService<UserManager<ApplicationUser>>();
        if (await userManager.FindByEmailAsync(demoEmail) is null)
        {
            var demo = new ApplicationUser
            {
                UserName = demoEmail,
                Email = demoEmail,
                FullName = config["DemoUser:Name"] ?? "Demo Voter",
                EmailConfirmed = true
            };
            var result = await userManager.CreateAsync(demo, demoPassword);
            if (!result.Succeeded)
            {
                logger.LogWarning("Could not create demo user: {Errors}",
                    string.Join("; ", result.Errors.Select(e => e.Description)));
            }
        }
    }
}
