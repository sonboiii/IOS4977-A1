using Microsoft.EntityFrameworkCore;
using MunicipalElections.Api.Data;
using MunicipalElections.Api.Models;

namespace MunicipalElections.Api.Services;

/// <summary>
/// Assignment 2: municipality-based filtering. Every election query that takes ?city=
/// resolves the name to a single municipality first, so records from other
/// municipalities can never be returned.
/// </summary>
public static class CityFilter
{
    /// <summary>
    /// Finds the municipality whose name matches <paramref name="city"/> (case-insensitive, trimmed).
    /// Returns null when no municipality has that name.
    /// </summary>
    public static Task<Municipality?> FindMunicipalityAsync(this AppDbContext db, string city)
    {
        var name = city.Trim().ToLower();
        return db.Municipalities
            .AsNoTracking()
            .FirstOrDefaultAsync(m => m.Name.ToLower() == name);
    }
}
