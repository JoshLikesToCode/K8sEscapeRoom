using System.Security.Cryptography;
using K8sEscapeRoom.Api.Services.Auth;
using K8sEscapeRoom.Api.Services.Storage;
using K8sEscapeRoom.Api.Validation;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Azure.Functions.Worker;

namespace K8sEscapeRoom.Api.Functions;

/// <summary>
/// POST /api/rooms/{roomId}/attempt - Start a new completion attempt
///
/// Generates a nonce that must be used with the CLI proof command.
/// The nonce expires after 30 minutes and can only be used once.
/// </summary>
public class StartAttempt
{
    private readonly IAuthService _authService;
    private readonly IAttemptStorage _attemptStorage;
    private static readonly TimeSpan NonceTtl = TimeSpan.FromMinutes(30);

    public StartAttempt(IAuthService authService, IAttemptStorage attemptStorage)
    {
        _authService = authService;
        _attemptStorage = attemptStorage;
    }

    [Function("StartAttempt")]
    public async Task<IActionResult> Run(
        [HttpTrigger(AuthorizationLevel.Anonymous, "post", Route = "rooms/{roomId}/attempt")] HttpRequest req,
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

        // Require authentication
        var user = _authService.GetUser(req);
        if (user == null)
        {
            return new UnauthorizedObjectResult(new { error = "Authentication required" });
        }

        // Generate nonce (24 bytes = 32 chars base64url)
        var nonceBytes = RandomNumberGenerator.GetBytes(24);
        var nonce = Convert.ToBase64String(nonceBytes)
            .Replace('+', '-')
            .Replace('/', '_')
            .TrimEnd('=');

        // Create attempt
        var attempt = await _attemptStorage.CreateAttemptAsync(user.Id, roomId, nonce, NonceTtl);

        return new OkObjectResult(new
        {
            roomId,
            nonce = attempt.Nonce,
            expiresAtUtc = attempt.ExpiresAtUtc.ToString("o")
        });
    }
}
