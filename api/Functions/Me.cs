using K8sEscapeRoom.Api.Models;
using K8sEscapeRoom.Api.Services.Auth;
using K8sEscapeRoom.Api.Services.Storage;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Azure.Functions.Worker;

namespace K8sEscapeRoom.Api.Functions;

/// <summary>
/// GET /api/me - Returns current user info and progress
/// </summary>
public class Me
{
    private readonly IAuthService _authService;
    private readonly IProgressStorage _progressStorage;

    public Me(IAuthService authService, IProgressStorage progressStorage)
    {
        _authService = authService;
        _progressStorage = progressStorage;
    }

    [Function("Me")]
    public async Task<IActionResult> Run(
        [HttpTrigger(AuthorizationLevel.Anonymous, "get", Route = "me")] HttpRequest req)
    {
        // Get authenticated user
        var user = _authService.GetUser(req);
        if (user == null)
        {
            return new UnauthorizedObjectResult(new { error = "Authentication required" });
        }

        // Get user's completed rooms
        var completedRooms = await _progressStorage.GetCompletedRoomsAsync(user.Id);

        var response = new UserProgress(user, completedRooms);

        return new OkObjectResult(response);
    }
}
