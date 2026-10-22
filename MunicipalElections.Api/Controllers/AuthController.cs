using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Identity;
using Microsoft.AspNetCore.Mvc;
using MunicipalElections.Api.DTOs;
using MunicipalElections.Api.Models;
using MunicipalElections.Api.Services;

namespace MunicipalElections.Api.Controllers;

[ApiController]
[Route("api/auth")]
[Produces("application/json")]
public class AuthController(UserManager<ApplicationUser> userManager, TokenService tokenService) : ControllerBase
{
    /// <summary>Create an account. Returns a JWT so the app can sign the user in immediately.</summary>
    [HttpPost("register")]
    [ProducesResponseType<AuthResponse>(StatusCodes.Status201Created)]
    [ProducesResponseType<ValidationProblemDetails>(StatusCodes.Status400BadRequest)]
    [ProducesResponseType<ProblemDetails>(StatusCodes.Status409Conflict)]
    public async Task<ActionResult<AuthResponse>> Register(RegisterRequest request)
    {
        var email = request.Email.Trim();

        if (await userManager.FindByEmailAsync(email) is not null)
        {
            return Problem(statusCode: StatusCodes.Status409Conflict,
                title: "An account with this email already exists.");
        }

        var user = new ApplicationUser
        {
            UserName = email,
            Email = email,
            FullName = request.Name.Trim()
        };

        var result = await userManager.CreateAsync(user, request.Password);
        if (!result.Succeeded)
        {
            foreach (var error in result.Errors)
            {
                ModelState.AddModelError(error.Code, error.Description);
            }
            return ValidationProblem(ModelState);
        }

        return StatusCode(StatusCodes.Status201Created, BuildResponse(user));
    }

    /// <summary>Sign in. Successful login returns { "token": "jwt-token-here", ... }.</summary>
    [HttpPost("login")]
    [ProducesResponseType<AuthResponse>(StatusCodes.Status200OK)]
    [ProducesResponseType<ProblemDetails>(StatusCodes.Status401Unauthorized)]
    public async Task<ActionResult<AuthResponse>> Login(LoginRequest request)
    {
        var user = await userManager.FindByEmailAsync(request.Email.Trim());
        if (user is null || !await userManager.CheckPasswordAsync(user, request.Password))
        {
            return Problem(statusCode: StatusCodes.Status401Unauthorized,
                title: "Invalid email or password.");
        }

        return Ok(BuildResponse(user));
    }

    /// <summary>The currently signed-in user (for the app's Profile screen).</summary>
    [Authorize]
    [HttpGet("me")]
    [ProducesResponseType<UserDto>(StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    public async Task<ActionResult<UserDto>> Me()
    {
        var userId = User.GetUserId();
        var user = userId is null ? null : await userManager.FindByIdAsync(userId);
        if (user is null)
        {
            return Unauthorized();
        }

        return ToDto(user);
    }

    private AuthResponse BuildResponse(ApplicationUser user)
    {
        var (token, expiresAt) = tokenService.CreateToken(user);
        return new AuthResponse { Token = token, ExpiresAt = expiresAt, User = ToDto(user) };
    }

    private static UserDto ToDto(ApplicationUser user) => new()
    {
        Id = user.Id,
        Name = user.FullName,
        Email = user.Email ?? string.Empty
    };
}
