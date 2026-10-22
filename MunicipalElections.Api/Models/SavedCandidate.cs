using System.ComponentModel.DataAnnotations;

namespace MunicipalElections.Api.Models;

/// <summary>
/// A candidate a user has added to their personal voting guide.
/// </summary>
public class SavedCandidate
{
    public int SavedCandidateId { get; set; }

    [Required]
    public string UserId { get; set; } = string.Empty;
    public ApplicationUser? User { get; set; }

    public int CandidateId { get; set; }
    public Candidate? Candidate { get; set; }

    /// <summary>Stored and returned as UTC.</summary>
    public DateTime DateSaved { get; set; }
}
