namespace K8sEscapeRoom.Api.Validation;

/// <summary>
/// Validates room IDs for the K8s Escape Room API.
/// Room IDs must start with an allowed prefix (room- or boss-).
/// </summary>
public static class RoomIdValidator
{
    private static readonly string[] AllowedPrefixes = ["room-", "boss-"];

    /// <summary>
    /// Check if a room ID is valid.
    /// </summary>
    public static bool IsValid(string? roomId)
    {
        if (string.IsNullOrWhiteSpace(roomId))
        {
            return false;
        }

        return AllowedPrefixes.Any(prefix =>
            roomId.StartsWith(prefix, StringComparison.OrdinalIgnoreCase));
    }

    /// <summary>
    /// Get the validation error message for an invalid room ID.
    /// </summary>
    public static string GetErrorMessage()
    {
        return $"Room ID must start with one of: {string.Join(", ", AllowedPrefixes)}";
    }
}
