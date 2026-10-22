using System.ComponentModel.DataAnnotations;
using Microsoft.AspNetCore.Identity;

namespace MunicipalElections.Api.Models;

/// <summary>
/// The User entity, managed through ASP.NET Core Identity.
/// Adds a display name to the standard Identity user.
/// </summary>
public class ApplicationUser : IdentityUser
{
    [MaxLength(100)]
    public string FullName { get; set; } = string.Empty;

    public ICollection<SavedCandidate> SavedCandidates { get; set; } = new List<SavedCandidate>();
}
