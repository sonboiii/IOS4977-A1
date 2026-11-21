using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using MunicipalElections.Api.Data;
using MunicipalElections.Api.DTOs;
using MunicipalElections.Api.Services;

namespace MunicipalElections.Api.Controllers;

/// <summary>
/// Assignment 2: election information per municipality (election date, offices and seats).
/// </summary>
[ApiController]
[Route("api/elections")]
[Produces("application/json")]
public class ElectionsController(AppDbContext db) : ControllerBase
{
    /// <summary>
    /// Elections, each with the offices up for election and their seat counts.
    /// Filter with ?city= (e.g. GET /api/elections?city=Burnaby). An unknown city returns 404.
    /// </summary>
    [HttpGet]
    [ProducesResponseType<IEnumerable<MunicipalityDetailDto>>(StatusCodes.Status200OK)]
    [ProducesResponseType<ProblemDetails>(StatusCodes.Status404NotFound)]
    public async Task<ActionResult<IEnumerable<MunicipalityDetailDto>>> GetAll([FromQuery] string? city)
    {
        var query = db.Municipalities.AsNoTracking();

        if (!string.IsNullOrWhiteSpace(city))
        {
            var municipality = await db.FindMunicipalityAsync(city);
            if (municipality is null)
            {
                return Problem(statusCode: StatusCodes.Status404NotFound,
                    title: $"Municipality '{city.Trim()}' not found.");
            }
            query = query.Where(m => m.MunicipalityId == municipality.MunicipalityId);
        }

        // Positions are loaded in a second query rather than projected inline:
        // SQLite cannot translate the nested collection projection (OUTER APPLY).
        var elections = await query
            .OrderBy(m => m.Name)
            .Select(m => new MunicipalityDetailDto
            {
                MunicipalityId = m.MunicipalityId,
                Name = m.Name,
                Province = m.Province,
                ElectionDate = m.ElectionDate,
                Description = m.Description,
                LogoUrl = m.LogoUrl,
                CandidateCount = m.Candidates.Count
            })
            .ToListAsync();

        var ids = elections.Select(e => e.MunicipalityId).ToList();
        var positions = await db.Positions
            .AsNoTracking()
            .Where(p => ids.Contains(p.MunicipalityId))
            .OrderBy(p => p.PositionId)
            .SelectDto()
            .ToListAsync();

        foreach (var election in elections)
        {
            election.Positions.AddRange(positions.Where(p => p.MunicipalityId == election.MunicipalityId));
        }

        return Ok(elections);
    }
}
