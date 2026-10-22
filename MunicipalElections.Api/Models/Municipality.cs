using System.ComponentModel.DataAnnotations;

namespace MunicipalElections.Api.Models;

public class Municipality
{
    public int MunicipalityId { get; set; }

    [Required, MaxLength(100)]
    public string Name { get; set; } = string.Empty;

    [Required, MaxLength(50)]
    public string Province { get; set; } = string.Empty;

    public DateOnly ElectionDate { get; set; }

    [MaxLength(1000)]
    public string? Description { get; set; }

    [MaxLength(500)]
    public string? LogoUrl { get; set; }

    public ICollection<Position> Positions { get; set; } = new List<Position>();
    public ICollection<Candidate> Candidates { get; set; } = new List<Candidate>();
}
