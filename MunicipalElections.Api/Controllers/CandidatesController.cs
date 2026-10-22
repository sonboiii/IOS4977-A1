using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using MunicipalElections.Api.Data;
using MunicipalElections.Api.DTOs;
using MunicipalElections.Api.Models;

namespace MunicipalElections.Api.Controllers;

[ApiController]
[Route("api/candidates")]
[Produces("application/json")]
public class CandidatesController(AppDbContext db) : ControllerBase
{
    /// <summary>
    /// All candidates. Optional filters for the app's directory screen:
    /// ?municipalityId=, ?positionId=, ?name= (partial, case-insensitive).
    /// </summary>
    [HttpGet]
    public async Task<ActionResult<IEnumerable<CandidateDto>>> GetAll(
        [FromQuery] int? municipalityId,
        [FromQuery] int? positionId,
        [FromQuery] string? name)
    {
        var query = db.Candidates.AsNoTracking();

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

    [HttpGet("{id:int}")]
    [ProducesResponseType<CandidateDto>(StatusCodes.Status200OK)]
    [ProducesResponseType<ProblemDetails>(StatusCodes.Status404NotFound)]
    public async Task<ActionResult<CandidateDto>> GetById(int id)
    {
        var candidate = await db.Candidates
            .AsNoTracking()
            .Where(c => c.CandidateId == id)
            .SelectDto()
            .FirstOrDefaultAsync();

        if (candidate is null)
        {
            return Problem(statusCode: StatusCodes.Status404NotFound, title: $"Candidate {id} not found.");
        }

        return candidate;
    }

    /// <summary>Search candidates by name: GET /api/candidates/search?name=chen</summary>
    [HttpGet("search")]
    public async Task<ActionResult<IEnumerable<CandidateDto>>> Search([FromQuery] string? name)
    {
        var query = FilterByName(db.Candidates.AsNoTracking(), name);
        return Ok(await Ordered(query).SelectDto().ToListAsync());
    }

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
