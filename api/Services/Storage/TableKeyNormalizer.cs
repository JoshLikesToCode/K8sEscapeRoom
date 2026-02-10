namespace K8sEscapeRoom.Api.Services.Storage;

/// <summary>
/// Normalizes keys for Azure Table Storage.
/// Table Storage disallows: / \ # ? in PartitionKey and RowKey.
/// This helper ensures consistent normalization across all storage operations.
/// </summary>
public static class TableKeyNormalizer
{
    /// <summary>
    /// Normalize a user ID for use as a Table Storage key.
    /// </summary>
    public static string NormalizeUserId(string userId)
    {
        return NormalizeKey(userId);
    }

    /// <summary>
    /// Normalize a room ID for use as a Table Storage key.
    /// </summary>
    public static string NormalizeRoomId(string roomId)
    {
        return NormalizeKey(roomId);
    }

    /// <summary>
    /// Normalize any string for use as a Table Storage key.
    /// Replaces disallowed characters with underscores.
    /// </summary>
    private static string NormalizeKey(string key)
    {
        if (string.IsNullOrEmpty(key))
        {
            return key;
        }

        // Table Storage disallows: / \ # ?
        return key
            .Replace("/", "_")
            .Replace("\\", "_")
            .Replace("#", "_")
            .Replace("?", "_");
    }
}
