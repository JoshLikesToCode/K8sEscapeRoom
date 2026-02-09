using System.Collections.Concurrent;
using K8sEscapeRoom.Api.Models;

namespace K8sEscapeRoom.Api.Services.Storage;

/// <summary>
/// In-memory implementation of attempt storage for development.
/// Attempts are lost on restart.
/// </summary>
public class InMemoryAttemptStorage : IAttemptStorage
{
    private readonly ConcurrentDictionary<string, AttemptEntity> _attempts = new();

    private static string GetKey(string userId, string roomId) => $"{userId}|{roomId}";

    public Task<AttemptEntity> CreateAttemptAsync(string userId, string roomId, string nonce, TimeSpan ttl)
    {
        var attempt = new AttemptEntity(userId, roomId, nonce, ttl);
        _attempts[GetKey(userId, roomId)] = attempt;
        return Task.FromResult(attempt);
    }

    public Task<AttemptEntity?> GetAttemptAsync(string userId, string roomId)
    {
        _attempts.TryGetValue(GetKey(userId, roomId), out var attempt);
        return Task.FromResult(attempt);
    }

    public Task MarkAttemptUsedAsync(string userId, string roomId)
    {
        if (_attempts.TryGetValue(GetKey(userId, roomId), out var attempt))
        {
            attempt.IsUsed = true;
            attempt.UsedAtUtc = DateTimeOffset.UtcNow;
        }
        return Task.CompletedTask;
    }
}
