using Microsoft.AspNetCore.Identity.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore;
using MunicipalElections.Api.Models;

namespace MunicipalElections.Api.Data;

public class AppDbContext(DbContextOptions<AppDbContext> options)
    : IdentityDbContext<ApplicationUser>(options)
{
    public DbSet<Municipality> Municipalities => Set<Municipality>();
    public DbSet<Position> Positions => Set<Position>();
    public DbSet<Candidate> Candidates => Set<Candidate>();
    public DbSet<SavedCandidate> SavedCandidates => Set<SavedCandidate>();

    protected override void OnModelCreating(ModelBuilder builder)
    {
        // Identity tables (AspNetUsers, AspNetRoles, ...)
        base.OnModelCreating(builder);

        builder.Entity<Position>()
            .HasOne(p => p.Municipality)
            .WithMany(m => m.Positions)
            .HasForeignKey(p => p.MunicipalityId)
            .OnDelete(DeleteBehavior.Cascade);

        builder.Entity<Candidate>(c =>
        {
            c.HasOne(x => x.Position)
                .WithMany(p => p.Candidates)
                .HasForeignKey(x => x.PositionId)
                .OnDelete(DeleteBehavior.Restrict);

            c.HasOne(x => x.Municipality)
                .WithMany(m => m.Candidates)
                .HasForeignKey(x => x.MunicipalityId)
                .OnDelete(DeleteBehavior.Restrict);

            c.HasIndex(x => x.Name);
        });

        builder.Entity<SavedCandidate>(s =>
        {
            s.HasOne(x => x.User)
                .WithMany(u => u.SavedCandidates)
                .HasForeignKey(x => x.UserId)
                .OnDelete(DeleteBehavior.Cascade);

            s.HasOne(x => x.Candidate)
                .WithMany(c => c.SavedBy)
                .HasForeignKey(x => x.CandidateId)
                .OnDelete(DeleteBehavior.Cascade);

            // A user can save a given candidate only once.
            s.HasIndex(x => new { x.UserId, x.CandidateId }).IsUnique();

            // SQLite has no timezone; mark values read back as UTC so JSON gets a trailing "Z".
            s.Property(x => x.DateSaved)
                .HasConversion(v => v, v => DateTime.SpecifyKind(v, DateTimeKind.Utc));
        });

        SeedData.Apply(builder);
    }
}
