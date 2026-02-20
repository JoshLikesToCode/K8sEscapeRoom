using System.Text.RegularExpressions;

namespace K8sEscapeRoom.Api.Validation;

/// <summary>
/// Validates room IDs for the K8s Escape Room API.
/// Room IDs must:
/// - Start with "room-", "boss-", or "final-"
/// - Contain only lowercase letters, digits, and hyphens after the prefix
/// - Not contain path separators or other special characters
/// </summary>
public static partial class RoomIdValidator
{
    /// <summary>
    /// Pattern: ^(room|boss|final)-[a-z0-9-]+$
    /// Examples of valid IDs: room-groundhog-deploy, boss-checkout-meltdown, final-cascading-outage
    /// </summary>
    [GeneratedRegex(@"^(room|boss|final)-[a-z0-9-]+$", RegexOptions.Compiled)]
    private static partial Regex ValidRoomIdPattern();

    /// <summary>
    /// Check if a room ID is valid.
    /// </summary>
    public static bool IsValid(string? roomId)
    {
        if (string.IsNullOrWhiteSpace(roomId))
        {
            return false;
        }

        // Reject any path separators explicitly (defense in depth)
        if (roomId.Contains('/') || roomId.Contains('\\'))
        {
            return false;
        }

        return ValidRoomIdPattern().IsMatch(roomId);
    }

    /// <summary>
    /// Get the validation error message for an invalid room ID.
    /// </summary>
    public static string GetErrorMessage()
    {
        return "Room ID must start with 'room-', 'boss-', or 'final-' and contain only lowercase letters, digits, and hyphens";
    }

    /// <summary>
    /// Get a detailed validation error for a specific room ID.
    /// </summary>
    public static string GetErrorMessage(string? roomId)
    {
        if (string.IsNullOrWhiteSpace(roomId))
        {
            return "Room ID is required";
        }

        if (roomId.Contains('/') || roomId.Contains('\\'))
        {
            return "Room ID must not contain path separators";
        }

        if (!roomId.StartsWith("room-") && !roomId.StartsWith("boss-") && !roomId.StartsWith("final-"))
        {
            return "Room ID must start with 'room-', 'boss-', or 'final-'";
        }

        return "Room ID must contain only lowercase letters, digits, and hyphens after the prefix";
    }
}
