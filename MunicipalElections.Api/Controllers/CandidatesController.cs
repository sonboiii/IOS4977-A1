using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using MunicipalElections.Api.Data;
using MunicipalElections.Api.DTOs;
using MunicipalElections.Api.Models;
using MunicipalElections.Api.Services;

namespace MunicipalElections.Api.Controllers;

[ApiController]
[Route("api/candidates")]
[Produces("application/json")]
public class CandidatesController(AppDbContext db) : ControllerBase
{
    /// <summary>
    /// All candidates. Optional filters for the app's directory screen:
    /// ?city= (municipality name, e.g. Burnaby), ?municipalityId=, ?positionId=,
    /// ?name= (partial, case-insensitive). An unknown city returns 404.
    /// </summary>
    [HttpGet]
    [ProducesResponseType<IEnumerable<CandidateDto>>(StatusCodes.Status200OK)]
    [ProducesResponseType<ProblemDetails>(StatusCodes.Status404NotFound)]
    public async Task<ActionResult<IEnumerable<CandidateDto>>> GetAll(
        [FromQuery] string? city,
        [FromQuery] int? municipalityId,
        [FromQuery] int? positionId,
        [FromQuery] string? name)
    {
        var query = db.Candidates.AsNoTracking();

        if (!string.IsNullOrWhiteSpace(city))
        {
            var municipality = await db.FindMunicipalityAsync(city);
            if (municipality is null)
            {
                return UnknownCity(city);
            }
            query = query.Where(c => c.MunicipalityId == municipality.MunicipalityId);
        }

        if (municipalityId is not null)
        {
            query = query.Where(c => c.MunicipalityId == municipalityId);
        }

        if (positionId is not null)
        {
            query = query.Where(c => c.PositionId == positionId);
        }

        query = FilterByName(query, name);

        return Ok(await Ordered(query).SelectDto().ToListAsync());
    }

    /// <summary>
    /// One candidate. With ?city=, a candidate from another municipality returns 404,
    /// so the app cannot show data outside the configured municipality.
    /// </summary>
    [HttpGet("{id:int}")]
    [ProducesResponseType<CandidateDto>(StatusCodes.Status200OK)]
    [ProducesResponseType<ProblemDetails>(StatusCodes.Status404NotFound)]
    public async Task<ActionResult<CandidateDto>> GetById(int id, [FromQuery] string? city)
    {
        var candidate = await db.Candidates
            .AsNoTracking()
            .Where(c => c.CandidateId == id)
            .SelectDto()
            .FirstOrDefaultAsync();

        if (candidate is null ||
            (!string.IsNullOrWhiteSpace(city) &&
             !string.Equals(candidate.MunicipalityName, city.Trim(), StringComparison.OrdinalIgnoreCase)))
        {
            return Problem(statusCode: StatusCodes.Status404NotFound, title: $"Candidate {id} not found.");
        }

        return candidate;
    }

    /// <summary>Search candidates by name: GET /api/candidates/search?name=chen&amp;city=Burnaby</summary>
    [HttpGet("search")]
    [ProducesResponseType<IEnumerable<CandidateDto>>(StatusCodes.Status200OK)]
    [ProducesResponseType<ProblemDetails>(StatusCodes.Status404NotFound)]
    public async Task<ActionResult<IEnumerable<CandidateDto>>> Search(
        [FromQuery] string? name,
        [FromQuery] string? city)
    {
        var query = db.Candidates.AsNoTracking();

        if (!string.IsNullOrWhiteSpace(city))
        {
            var municipality = await db.FindMunicipalityAsync(city);
            if (municipality is null)
            {
                return UnknownCity(city);
            }
            query = query.Where(c => c.MunicipalityId == municipality.MunicipalityId);
        }

        query = FilterByName(query, name);
        return Ok(await Ordered(query).SelectDto().ToListAsync());
    }

    private ObjectResult UnknownCity(string city) =>
        Problem(statusCode: StatusCodes.Status404NotFound, title: $"Municipality '{city.Trim()}' not found.");

    private static IQueryable<Candidate> FilterByName(IQueryable<Candidate> query, string? name)
    {
        if (string.IsNullOrWhiteSpace(name))
        {
            return query;
        }

        var term = name.Trim().ToLower();
        return query.Where(c => c.Name.ToLower().Contains(term));
    }

    private static IQueryable<Candidate> Ordered(IQueryable<Candidate> query) =>
        query.OrderBy(c => c.Municipality!.Name)
             .ThenBy(c => c.PositionId)
             .ThenBy(c => c.Name);
}
