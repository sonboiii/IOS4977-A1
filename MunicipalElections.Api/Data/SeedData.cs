using Microsoft.EntityFrameworkCore;
using MunicipalElections.Api.Models;

namespace MunicipalElections.Api.Data;

/// <summary>
/// Code-first seed data (applied through migrations via HasData).
/// All candidates are fictional and exist only for this assignment.
/// </summary>
public static class SeedData
{
    // BC general local elections are held on the third Saturday of October.
    private static readonly DateOnly ElectionDay = new(2026, 10, 17);

    private const string Bc = "British Columbia";

    public static void Apply(ModelBuilder builder)
    {
        builder.Entity<Municipality>().HasData(
            new Municipality
            {
                MunicipalityId = 1,
                Name = "Pitt Meadows",
                Province = Bc,
                ElectionDate = ElectionDay,
                Description = "A small city in Metro Vancouver between the Pitt and Fraser rivers, known for its farmland, dyke trails and regional airport.",
                LogoUrl = Logo("Pitt Meadows", "2E7D32")
            },
            new Municipality
            {
                MunicipalityId = 2,
                Name = "Maple Ridge",
                Province = Bc,
                ElectionDate = ElectionDay,
                Description = "A growing city on the north side of the Fraser River at the foot of the Golden Ears mountains.",
                LogoUrl = Logo("Maple Ridge", "1565C0")
            },
            new Municipality
            {
                MunicipalityId = 3,
                Name = "Burnaby",
                Province = Bc,
                ElectionDate = ElectionDay,
                Description = "Metro Vancouver's third-largest city, home to Metrotown, Simon Fraser University and BCIT.",
                LogoUrl = Logo("Burnaby", "6A1B9A")
            });

        // Each municipality elects a Mayor, Councillors and School Trustees.
        // Pitt Meadows and Maple Ridge share School District 42 (2 + 5 trustees); Burnaby is SD 41 (7).
        builder.Entity<Position>().HasData(
            new Position { PositionId = 1, Name = "Mayor", SeatsAvailable = 1, MunicipalityId = 1 },
            new Position { PositionId = 2, Name = "Councillor", SeatsAvailable = 6, MunicipalityId = 1 },
            new Position { PositionId = 3, Name = "School Trustee", SeatsAvailable = 2, MunicipalityId = 1 },

            new Position { PositionId = 4, Name = "Mayor", SeatsAvailable = 1, MunicipalityId = 2 },
            new Position { PositionId = 5, Name = "Councillor", SeatsAvailable = 6, MunicipalityId = 2 },
            new Position { PositionId = 6, Name = "School Trustee", SeatsAvailable = 5, MunicipalityId = 2 },

            new Position { PositionId = 7, Name = "Mayor", SeatsAvailable = 1, MunicipalityId = 3 },
            new Position { PositionId = 8, Name = "Councillor", SeatsAvailable = 8, MunicipalityId = 3 },
            new Position { PositionId = 9, Name = "School Trustee", SeatsAvailable = 7, MunicipalityId = 3 });

        builder.Entity<Candidate>().HasData(
            // ---- Pitt Meadows ----
            C(1, "Elena Marsh", 1, 1, "Two-term councillor and former small-business owner focused on protecting farmland and improving the Harris Road underpass traffic flow."),
            C(2, "Raj Sandhu", 1, 1, "Civil engineer and Pitt Meadows Day volunteer running on infrastructure renewal and a balanced budget."),
            C(3, "Megan O'Leary", 2, 1, "Registered nurse campaigning for expanded seniors' services and more family doctors in the community."),
            C(4, "Thomas Nguyen", 2, 1, "Youth soccer coach advocating for new recreation facilities and safer cycling routes along the dykes."),
            C(5, "Priya Kaur", 3, 1, "Parent advisory council chair committed to smaller class sizes and school meal programs."),
            C(6, "Daniel Fraser", 3, 1, "Retired teacher with 30 years in SD 42 classrooms, focused on literacy and special-education support."),

            // ---- Maple Ridge ----
            C(7, "Samantha Cole", 4, 2, "Former city planner promising faster housing approvals and a revitalized downtown core."),
            C(8, "Marcus Bell", 4, 2, "Local entrepreneur running on property-tax restraint, public safety and support for local business."),
            C(9, "Aisha Rahman", 5, 2, "Environmental scientist championing park protection around Golden Ears and Kanaka Creek."),
            C(10, "Kevin Brooks", 5, 2, "Firefighter and union steward focused on emergency preparedness and wildfire resilience."),
            C(11, "Linda Park", 6, 2, "Early-childhood educator advocating for full-day child care spaces in schools."),
            C(12, "Jordan Ellis", 6, 2, "Software developer pushing for modern technology and digital-literacy programs across SD 42."),

            // ---- Burnaby ----
            C(13, "Victor Chen", 7, 3, "Three-term councillor focused on affordable rental housing near SkyTrain stations."),
            C(14, "Grace Morales", 7, 3, "Community-centre director running on accessible recreation, libraries and transit."),
            C(15, "Hassan Ali", 8, 3, "SFU urban-studies lecturer advocating for complete, walkable neighbourhoods."),
            C(16, "Olivia Wright", 8, 3, "Small-business owner on Hastings Street focused on reducing red tape and supporting local shops."),
            C(17, "Ben Tanaka", 8, 3, "BCIT graduate and climate-action organizer calling for more bike lanes and urban tree canopy."),
            C(18, "Sofia Petrov", 9, 3, "Parent and ESL instructor focused on newcomer student support and seismic school upgrades."),
            C(19, "Michael Osei", 9, 3, "Accountant and former PAC treasurer promising transparent budgets for SD 41."));
    }

    private static Candidate C(int id, string name, int positionId, int municipalityId, string bio)
    {
        var slug = name.ToLowerInvariant().Replace(" ", ".").Replace("'", "");
        return new Candidate
        {
            CandidateId = id,
            Name = name,
            Biography = bio,
            PhotoUrl = $"https://ui-avatars.com/api/?name={Uri.EscapeDataString(name)}&size=256&background=0D8ABC&color=fff&format=png",
            Website = $"https://example.com/{slug}",
            Email = $"{slug}@example.com",
            PositionId = positionId,
            MunicipalityId = municipalityId
        };
    }

    // Placeholder logo images. Swap these for official logo PNG URLs if you prefer.
    private static string Logo(string name, string colour) =>
        $"https://ui-avatars.com/api/?name={Uri.EscapeDataString(name)}&size=256&background={colour}&color=fff&format=png&bold=true";
}
