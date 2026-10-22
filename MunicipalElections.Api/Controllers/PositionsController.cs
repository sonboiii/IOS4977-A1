using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using MunicipalElections.Api.Data;
using MunicipalElections.Api.DTOs;

namespace MunicipalElections.Api.Controllers;

[ApiController]
[Route("api/positions")]
[Produces("application/json")]
public class PositionsController(AppDbContext db) : ControllerBase
{
    /// <summary>All positions. Optionally filter with ?municipalityId=.</summary>
    [HttpGet]
    public async Task<ActionResult<IEnumerable<PositionDto>>> GetAll([FromQuery] int? municipalityId)
    {
        var query = db.Positions.AsNoTracking();

        if (municipalityId is not null)
        {
            query = query.Where(p => p.MunicipalityId == municipalityId);
        }

        var positions = await query
            .OrderBy(p => p.Municipality!.Name)
            .ThenBy(p => p.PositionId)
            .SelectDto()
            .ToListAsync();

        return Ok(positions);
    }

    [HttpGet("{id:int}")]
    [ProducesResponseType<PositionDto>(StatusCodes.Status200OK)]
    [ProducesResponseType<ProblemDetails>(StatusCodes.Status404NotFound)]
    public async Task<ActionResult<PositionDto>> GetById(int id)
    {
        var position = await db.Positions
            .AsNoTracking()
            .Where(p => p.PositionId == id)
            .SelectDto()
            .FirstOrDefaultAsync();

        if (position is null)
        {
            return Problem(statusCode: StatusCodes.Status404NotFound, title: $"Position {id} not found.");
        }

        return position;
    }
}
