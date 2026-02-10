using Azure;
using Azure.Data.Tables;

namespace K8sEscapeRoom.Api.Models;

/// <summary>
/// Represents a user's completion of a room.
/// PartitionKey = UserId, RowKey = RoomId
/// </summary>
public class RoomProgressEntity : ITableEntity
{
    /// <summary>
    /// User ID (partition key for efficient user queries)
    /// </summary>
    public string PartitionKey { get; set; } = string.Empty;

    /// <summary>
    /// Room ID (row key)
    /// </summary>
    public string RowKey { get; set; } = string.Empty;

    /// <summary>
    /// When the room was completed (UTC)
    /// </summary>
    public DateTimeOffset CompletedAt { get; set; }

    /// <summary>
    /// Original room ID before normalization (for display purposes)
    /// </summary>
    public string? OriginalRoomId { get; set; }

    /// <summary>
    /// Optional: Version of the room when completed (for future-proofing)
    /// </summary>
    public string? CompletedByVersion { get; set; }

    public DateTimeOffset? Timestamp { get; set; }
    public ETag ETag { get; set; }

    /// <summary>
    /// Convenience property for UserId
    /// </summary>
    public string UserId => PartitionKey;

    /// <summary>
    /// Convenience property for RoomId (returns original if available)
    /// </summary>
    public string RoomId => OriginalRoomId ?? RowKey;

    public RoomProgressEntity() { }

    public RoomProgressEntity(string userId, string roomId)
    {
        PartitionKey = userId;
        RowKey = roomId;
        CompletedAt = DateTimeOffset.UtcNow;
    }
}
