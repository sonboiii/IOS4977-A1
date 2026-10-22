using System.Security.Claims;
using Microsoft.IdentityModel.JsonWebTokens;

namespace MunicipalElections.Api.Services;

public static class ClaimsPrincipalExtensions
{
    /// <summary>The Identity user id stored in the token's "sub" claim.</summary>
    public static string? GetUserId(this ClaimsPrincipal user) =>
        user.FindFirstValue(JwtRegisteredClaimNames.Sub);
}
