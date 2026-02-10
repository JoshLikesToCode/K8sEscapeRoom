using Azure;
using Azure.Data.Tables;

namespace K8sEscapeRoom.Api.Models;

/// <summary>
/// Represents a room completion attempt with nonce for proof verification.
/// PartitionKey = UserId, RowKey = RoomId (last attempt per user+room).
/// </summary>
public class AttemptEntity : ITableEntity
{
    /// <summary>
    /// User ID (partition key)
    /// </summary>
    public string PartitionKey { get; set; } = string.Empty;

    /// <summary>
    /// Room ID (row key)
    /// </summary>
    public string RowKey { get; set; } = string.Empty;

    /// <summary>
    /// Original room ID before normalization (for API responses)
    /// </summary>
    public string? OriginalRoomId { get; set; }

    /// <summary>
    /// Random nonce for this attempt
    /// </summary>
    public string Nonce { get; set; } = string.Empty;

    /// <summary>
    /// When the attempt was issued
    /// </summary>
    public DateTimeOffset IssuedAtUtc { get; set; }

    /// <summary>
    /// When the nonce expires
    /// </summary>
    public DateTimeOffset ExpiresAtUtc { get; set; }

    /// <summary>
    /// When the nonce was used (null if not yet used)
    /// </summary>
    public DateTimeOffset? UsedAtUtc { get; set; }

    /// <summary>
    /// Whether this nonce has been used
    /// </summary>
    public bool IsUsed { get; set; }

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

    public AttemptEntity() { }

    /// <summary>
    /// Check if this attempt is expired
    /// </summary>
    public bool IsExpired => DateTimeOffset.UtcNow > ExpiresAtUtc;

    /// <summary>
    /// Check if this attempt can be used (not expired and not already used)
    /// </summary>
    public bool CanBeUsed => !IsUsed && !IsExpired;
}
