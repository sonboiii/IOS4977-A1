using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using MunicipalElections.Api.Data;
using MunicipalElections.Api.DTOs;
using MunicipalElections.Api.Models;
using MunicipalElections.Api.Services;

namespace MunicipalElections.Api.Controllers;

/// <summary>The signed-in user's personal voting guide. Requires Authorization: Bearer &lt;token&gt;.</summary>
[ApiController]
[Authorize]
[Route("api/savedcandidates")]
[Produces("application/json")]
[ProducesResponseType(StatusCodes.Status401Unauthorized)]
public class SavedCandidatesController(AppDbContext db) : ControllerBase
{
    /// <summary>The current user's saved candidates, newest first.</summary>
    [HttpGet]
    public async Task<ActionResult<IEnumerable<SavedCandidateDto>>> GetMine()
    {
        var userId = User.GetUserId();
        if (userId is null) return Unauthorized();

        var saved = await db.SavedCandidates
            .AsNoTracking()
            .Where(s => s.UserId == userId)
            .OrderByDescending(s => s.DateSaved)
            .SelectDto()
            .ToListAsync();

        return Ok(saved);
    }

    /// <summary>Add a candidate to the voting guide. Body: { "candidateId": 3 }</summary>
    [HttpPost]
    [ProducesResponseType<SavedCandidateDto>(StatusCodes.Status201Created)]
    [ProducesResponseType<ProblemDetails>(StatusCodes.Status404NotFound)]
    [ProducesResponseType<ProblemDetails>(StatusCodes.Status409Conflict)]
    public async Task<ActionResult<SavedCandidateDto>> Save(SaveCandidateRequest request)
    {
        var userId = User.GetUserId();
        if (userId is null) return Unauthorized();

        if (!await db.Candidates.AnyAsync(c => c.CandidateId == request.CandidateId))
        {
            return Problem(statusCode: StatusCodes.Status404NotFound,
                title: $"Candidate {request.CandidateId} not found.");
        }

        if (await db.SavedCandidates.AnyAsync(s => s.UserId == userId && s.CandidateId == request.CandidateId))
        {
            return Problem(statusCode: StatusCodes.Status409Conflict,
                title: "This candidate is already in your voting guide.");
        }

        var entity = new SavedCandidate
        {
            UserId = userId,
            CandidateId = request.CandidateId,
            DateSaved = DateTime.UtcNow
        };
        db.SavedCandidates.Add(entity);
        await db.SaveChangesAsync();

        var dto = await db.SavedCandidates
            .AsNoTracking()
            .Where(s => s.SavedCandidateId == entity.SavedCandidateId)
            .SelectDto()
            .FirstAsync();

        return StatusCode(StatusCodes.Status201Created, dto);
    }

    /// <summary>Remove an entry from the voting guide by its savedCandidateId.</summary>
    [HttpDelete("{id:int}")]
    [ProducesResponseType(StatusCodes.Status204NoContent)]
    [ProducesResponseType<ProblemDetails>(StatusCodes.Status404NotFound)]
    public async Task<IActionResult> Delete(int id)
    {
        var userId = User.GetUserId();
        if (userId is null) return Unauthorized();

        var entity = await db.SavedCandidates
            .FirstOrDefaultAsync(s => s.SavedCandidateId == id && s.UserId == userId);

        return await RemoveAsync(entity, $"Saved entry {id} not found in your voting guide.");
    }

    /// <summary>
    /// Convenience for the Candidate Details screen: remove by candidateId instead of savedCandidateId.
    /// </summary>
    [HttpDelete("candidate/{candidateId:int}")]
    [ProducesResponseType(StatusCodes.Status204NoContent)]
    [ProducesResponseType<ProblemDetails>(StatusCodes.Status404NotFound)]
    public async Task<IActionResult> DeleteByCandidate(int candidateId)
    {
        var userId = User.GetUserId();
        if (userId is null) return Unauthorized();

        var entity = await db.SavedCandidates
            .FirstOrDefaultAsync(s => s.CandidateId == candidateId && s.UserId == userId);

        return await RemoveAsync(entity, $"Candidate {candidateId} is not in your voting guide.");
    }

    private async Task<IActionResult> RemoveAsync(SavedCandidate? entity, string notFoundMessage)
    {
        if (entity is null)
        {
            return Problem(statusCode: StatusCodes.Status404NotFound, title: notFoundMessage);
        }

        db.SavedCandidates.Remove(entity);
        await db.SaveChangesAsync();
        return NoContent();
    }
}
