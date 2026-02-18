using K8sEscapeRoom.Api.Services.Auth;
using K8sEscapeRoom.Api.Services.Storage;
using K8sEscapeRoom.Api.Validation;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Azure.Functions.Worker;

namespace K8sEscapeRoom.Api.Functions;

/// <summary>
/// POST /api/rooms/{roomId}/complete - Mark a room as completed (dev/testing only)
///
/// DEPRECATED: Use the proof submission flow (StartAttempt + SubmitProof) instead.
/// This endpoint bypasses proof verification and exists only for development convenience.
/// </summary>
public class CompleteRoom
{
    private readonly IAuthService _authService;
    private readonly IProgressStorage _progressStorage;

    public CompleteRoom(IAuthService authService, IProgressStorage progressStorage)
    {
        _authService = authService;
        _progressStorage = progressStorage;
    }

    [Function("CompleteRoom")]
    public async Task<IActionResult> Run(
        [HttpTrigger(AuthorizationLevel.Anonymous, "post", Route = "rooms/{roomId}/complete")] HttpRequest req,
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

        // Mark room as complete (idempotent)
        await _progressStorage.MarkRoomCompleteAsync(user.Id, roomId);

        return new OkObjectResult(new
        {
            success = true,
            roomId,
            message = "Room marked as complete"
        });
    }
}
