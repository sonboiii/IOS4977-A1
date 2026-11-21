using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using MunicipalElections.Api.Data;
using MunicipalElections.Api.DTOs;
using MunicipalElections.Api.Services;

namespace MunicipalElections.Api.Controllers;

[ApiController]
[Route("api/positions")]
[Route("api/offices")] // Assignment 2 name: GET /api/offices?city=Burnaby
[Produces("application/json")]
public class PositionsController(AppDbContext db) : ControllerBase
{
    /// <summary>
    /// All positions (election offices). Filter with ?city= (municipality name) or ?municipalityId=.
    /// An unknown city returns 404.
    /// </summary>
    [HttpGet]
    [ProducesResponseType<IEnumerable<PositionDto>>(StatusCodes.Status200OK)]
    [ProducesResponseType<ProblemDetails>(StatusCodes.Status404NotFound)]
    public async Task<ActionResult<IEnumerable<PositionDto>>> GetAll(
        [FromQuery] string? city,
        [FromQuery] int? municipalityId)
    {
        var query = db.Positions.AsNoTracking();

        if (!string.IsNullOrWhiteSpace(city))
        {
            var municipality = await db.FindMunicipalityAsync(city);
            if (municipality is null)
            {
                return Problem(statusCode: StatusCodes.Status404NotFound,
                    title: $"Municipality '{city.Trim()}' not found.");
            }
            query = query.Where(p => p.MunicipalityId == municipality.MunicipalityId);
        }

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
