using System.Text.Json;
using K8sEscapeRoom.Api.Services.Auth;
using K8sEscapeRoom.Api.Services.Storage;
using K8sEscapeRoom.Api.Validation;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Azure.Functions.Worker;

namespace K8sEscapeRoom.Api.Functions;

/// <summary>
/// POST /api/rooms/{roomId}/submit - Submit a proof token
///
/// Validates the proof token against the active attempt nonce,
/// verifies the hash, and marks the room as completed.
/// </summary>
public class SubmitProof
{
    private readonly IAuthService _authService;
    private readonly IAttemptStorage _attemptStorage;
    private readonly IProgressStorage _progressStorage;

    public SubmitProof(
        IAuthService authService,
        IAttemptStorage attemptStorage,
        IProgressStorage progressStorage)
    {
        _authService = authService;
        _attemptStorage = attemptStorage;
        _progressStorage = progressStorage;
    }

    [Function("SubmitProof")]
    public async Task<IActionResult> Run(
        [HttpTrigger(AuthorizationLevel.Anonymous, "post", Route = "rooms/{roomId}/submit")] HttpRequest req,
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

        // Parse request body
        SubmitRequest? body;
        try
        {
            body = await JsonSerializer.DeserializeAsync<SubmitRequest>(
                req.Body,
                new JsonSerializerOptions { PropertyNameCaseInsensitive = true }
            );
        }
        catch
        {
            return new BadRequestObjectResult(new { error = "Invalid request body" });
        }

        if (body == null || string.IsNullOrWhiteSpace(body.Token))
        {
            return new BadRequestObjectResult(new { error = "Token is required" });
        }

        // Parse the token
        var parseResult = ProofTokenValidator.Parse(body.Token);
        if (!parseResult.IsValid)
        {
            return new BadRequestObjectResult(new
            {
                error = "Invalid token format",
                message = parseResult.Error
            });
        }

        // Verify token roomId matches route roomId
        if (!string.Equals(parseResult.RoomId, roomId, StringComparison.OrdinalIgnoreCase))
        {
            return new BadRequestObjectResult(new
            {
                error = "Room ID mismatch",
                message = "Token was generated for a different room"
            });
        }

        // Get the attempt for this user+room
        var attempt = await _attemptStorage.GetAttemptAsync(user.Id, roomId);
        if (attempt == null)
        {
            return new BadRequestObjectResult(new
            {
                error = "No active attempt",
                message = "Start a new attempt before submitting proof"
            });
        }

        // Check if attempt is already used
        if (attempt.IsUsed)
        {
            return new BadRequestObjectResult(new
            {
                error = "Nonce already used",
                message = "This attempt has already been completed. Start a new attempt."
            });
        }

        // Check if attempt is expired
        if (attempt.IsExpired)
        {
            return new BadRequestObjectResult(new
            {
                error = "Nonce expired",
                message = "This attempt has expired. Start a new attempt."
            });
        }

        // Verify nonce matches
        if (attempt.Nonce != parseResult.Nonce)
        {
            return new BadRequestObjectResult(new
            {
                error = "Nonce mismatch",
                message = "Token nonce does not match the active attempt"
            });
        }

        // Verify the hash
        if (!ProofTokenValidator.ValidateHash(
            parseResult.RoomId!,
            parseResult.Nonce!,
            parseResult.Timestamp!.Value,
            parseResult.Sha256!))
        {
            return new BadRequestObjectResult(new
            {
                error = "Invalid proof",
                message = "Token hash verification failed"
            });
        }

        // Success! Mark attempt as used and room as completed
        await _attemptStorage.MarkAttemptUsedAsync(user.Id, roomId);
        await _progressStorage.MarkRoomCompleteAsync(user.Id, roomId);

        return new OkObjectResult(new { ok = true });
    }

    private record SubmitRequest(string? Token);
}
