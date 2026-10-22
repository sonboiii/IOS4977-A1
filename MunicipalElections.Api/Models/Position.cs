using System.ComponentModel.DataAnnotations;

namespace MunicipalElections.Api.Models;

public class Position
{
    public int PositionId { get; set; }

    [Required, MaxLength(100)]
    public string Name { get; set; } = string.Empty;

    [Range(1, 50)]
    public int SeatsAvailable { get; set; }

    public int MunicipalityId { get; set; }
    public Municipality? Municipality { get; set; }

    public ICollection<Candidate> Candidates { get; set; } = new List<Candidate>();
}
