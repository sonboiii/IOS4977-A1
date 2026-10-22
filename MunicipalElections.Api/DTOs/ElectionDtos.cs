using System.ComponentModel.DataAnnotations;
using MunicipalElections.Api.Models;

namespace MunicipalElections.Api.DTOs;

public class MunicipalityDto
{
    public int MunicipalityId { get; init; }
    public string Name { get; init; } = string.Empty;
    public string Province { get; init; } = string.Empty;
    /// <summary>Serialized as "yyyy-MM-dd".</summary>
    public DateOnly ElectionDate { get; init; }
    public string? Description { get; init; }
    public string? LogoUrl { get; init; }
    public int CandidateCount { get; init; }
}

public class MunicipalityDetailDto : MunicipalityDto
{
    public List<PositionDto> Positions { get; init; } = [];
}

public class PositionDto
{
    public int PositionId { get; init; }
    public string Name { get; init; } = string.Empty;
    public int SeatsAvailable { get; init; }
    public int MunicipalityId { get; init; }
    public string MunicipalityName { get; init; } = string.Empty;
    public int CandidateCount { get; init; }
}

public class CandidateDto
{
    public int CandidateId { get; init; }
    public string Name { get; init; } = string.Empty;
    public string? Biography { get; init; }
    public string? PhotoUrl { get; init; }
    public string? Website { get; init; }
    public string? Email { get; init; }
    public int PositionId { get; init; }
    public string PositionName { get; init; } = string.Empty;
    public int MunicipalityId { get; init; }
    public string MunicipalityName { get; init; } = string.Empty;
}

public class SavedCandidateDto
{
    public int SavedCandidateId { get; init; }
    public int CandidateId { get; init; }
    public DateTime DateSaved { get; init; }
    public CandidateDto Candidate { get; init; } = new();
}

public class SaveCandidateRequest
{
    [Range(1, int.MaxValue)]
    public int CandidateId { get; set; }
}

/// <summary>EF-translatable projections shared by the controllers.</summary>
public static class DtoProjections
{
    public static IQueryable<CandidateDto> SelectDto(this IQueryable<Candidate> query) =>
        query.Select(c => new CandidateDto
        {
            CandidateId = c.CandidateId,
            Name = c.Name,
            Biography = c.Biography,
            PhotoUrl = c.PhotoUrl,
            Website = c.Website,
            Email = c.Email,
            PositionId = c.PositionId,
            PositionName = c.Position!.Name,
            MunicipalityId = c.MunicipalityId,
            MunicipalityName = c.Municipality!.Name
        });

    public static IQueryable<PositionDto> SelectDto(this IQueryable<Position> query) =>
        query.Select(p => new PositionDto
        {
            PositionId = p.PositionId,
            Name = p.Name,
            SeatsAvailable = p.SeatsAvailable,
            MunicipalityId = p.MunicipalityId,
            MunicipalityName = p.Municipality!.Name,
            CandidateCount = p.Candidates.Count
        });

    public static IQueryable<SavedCandidateDto> SelectDto(this IQueryable<SavedCandidate> query) =>
        query.Select(s => new SavedCandidateDto
        {
            SavedCandidateId = s.SavedCandidateId,
            CandidateId = s.CandidateId,
            DateSaved = s.DateSaved,
            Candidate = new CandidateDto
            {
                CandidateId = s.Candidate!.CandidateId,
                Name = s.Candidate.Name,
                Biography = s.Candidate.Biography,
                PhotoUrl = s.Candidate.PhotoUrl,
                Website = s.Candidate.Website,
                Email = s.Candidate.Email,
                PositionId = s.Candidate.PositionId,
                PositionName = s.Candidate.Position!.Name,
                MunicipalityId = s.Candidate.MunicipalityId,
                MunicipalityName = s.Candidate.Municipality!.Name
            }
        });
}
