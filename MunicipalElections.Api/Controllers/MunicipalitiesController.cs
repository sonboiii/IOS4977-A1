using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using MunicipalElections.Api.Data;
using MunicipalElections.Api.DTOs;

namespace MunicipalElections.Api.Controllers;

[ApiController]
[Route("api/municipalities")]
[Produces("application/json")]
public class MunicipalitiesController(AppDbContext db) : ControllerBase
{
    /// <summary>All municipalities, ordered by name.</summary>
    [HttpGet]
    public async Task<ActionResult<IEnumerable<MunicipalityDto>>> GetAll()
    {
        var municipalities = await db.Municipalities
            .AsNoTracking()
            .OrderBy(m => m.Name)
            .Select(m => new MunicipalityDto
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

        return Ok(municipalities);
    }

    /// <summary>One municipality, including the positions up for election.</summary>
    [HttpGet("{id:int}")]
    [ProducesResponseType<MunicipalityDetailDto>(StatusCodes.Status200OK)]
    [ProducesResponseType<ProblemDetails>(StatusCodes.Status404NotFound)]
    public async Task<ActionResult<MunicipalityDetailDto>> GetById(int id)
    {
        var municipality = await db.Municipalities
            .AsNoTracking()
            .Where(m => m.MunicipalityId == id)
            .Select(m => new MunicipalityDetailDto
            {
                MunicipalityId = m.MunicipalityId,
                Name = m.Name,
                Province = m.Province,
                ElectionDate = m.ElectionDate,
                Description = m.Description,
                LogoUrl = m.LogoUrl,
                CandidateCount = m.Candidates.Count,
                Positions = m.Positions
                    .OrderBy(p => p.PositionId)
                    .Select(p => new PositionDto
                    {
                        PositionId = p.PositionId,
                        Name = p.Name,
                        SeatsAvailable = p.SeatsAvailable,
                        MunicipalityId = p.MunicipalityId,
                        MunicipalityName = m.Name,
                        CandidateCount = p.Candidates.Count
                    })
                    .ToList()
            })
            .FirstOrDefaultAsync();

        if (municipality is null)
        {
            return Problem(statusCode: StatusCodes.Status404NotFound, title: $"Municipality {id} not found.");
        }

        return municipality;
    }
}
