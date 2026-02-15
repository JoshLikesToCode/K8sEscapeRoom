using K8sEscapeRoom.Api.Services.Auth;
using K8sEscapeRoom.Api.Services.Storage;
using K8sEscapeRoom.Api.Validation;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Azure.Functions.Worker;

namespace K8sEscapeRoom.Api.Functions;

/// <summary>
/// POST /api/rooms/{roomId}/reset - Reset progress for a room
/// </summary>
public class ResetRoom
{
    private readonly IAuthService _authService;
    private readonly IProgressStorage _progressStorage;

    public ResetRoom(IAuthService authService, IProgressStorage progressStorage)
    {
        _authService = authService;
        _progressStorage = progressStorage;
    }

    [Function("ResetRoom")]
    public async Task<IActionResult> Run(
        [HttpTrigger(AuthorizationLevel.Anonymous, "post", Route = "rooms/{roomId}/reset")] HttpRequest req,
        string roomId)
    {
        // Validate room ID
        if (!RoomIdValidator.IsValid(roomId))
        {
            return new BadRequestObjectResult(new
            {
                error = "Invalid room ID",
                message = RoomIdValidator.GetErrorMessage()
            });
        }

        // Get authenticated user
        var user = _authService.GetUser(req);
        if (user == null)
        {
            return new UnauthorizedObjectResult(new { error = "Authentication required" });
        }

        // Reset room progress (idempotent)
        await _progressStorage.ResetRoomProgressAsync(user.Id, roomId);

        return new OkObjectResult(new
        {
            success = true,
            roomId,
            message = "Room progress has been reset"
        });
    }
}
