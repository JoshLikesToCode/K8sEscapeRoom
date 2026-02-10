using K8sEscapeRoom.Api.Models;

namespace K8sEscapeRoom.Api.Services.Storage;

/// <summary>
/// Abstraction for room attempt storage.
/// Stores nonces and tracks attempt state for proof verification.
/// </summary>
public interface IAttemptStorage
{
    /// <summary>
    /// Create or replace an attempt for a user+room.
    /// Returns the created attempt.
    /// </summary>
    Task<AttemptEntity> CreateAttemptAsync(string userId, string roomId, string nonce, TimeSpan ttl);

    /// <summary>
    /// Get the current attempt for a user+room.
    /// Returns null if no attempt exists.
    /// </summary>
    Task<AttemptEntity?> GetAttemptAsync(string userId, string roomId);

    /// <summary>
    /// Mark an attempt as used.
    /// </summary>
    Task MarkAttemptUsedAsync(string userId, string roomId);
}
