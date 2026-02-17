namespace K8sEscapeRoom.Api.Services.Storage;

/// <summary>
/// Abstraction for room progress storage.
/// Can be backed by Azure Table Storage, Cosmos DB, or in-memory for dev.
/// </summary>
public interface IProgressStorage
{
    /// <summary>
    /// Get all completed room IDs for a user
    /// </summary>
    Task<IReadOnlyList<string>> GetCompletedRoomsAsync(string userId);

    /// <summary>
    /// Mark a room as completed for a user.
    /// Idempotent: calling twice has no effect.
    /// </summary>
    Task MarkRoomCompleteAsync(string userId, string roomId);

    /// <summary>
    /// Check if a specific room is completed by a user
    /// </summary>
    Task<bool> IsRoomCompletedAsync(string userId, string roomId);

    /// <summary>
    /// Reset progress for a specific room (remove completion).
    /// Idempotent: calling on an incomplete room has no effect.
    /// </summary>
    Task ResetRoomProgressAsync(string userId, string roomId);
}
