using System.Collections.Concurrent;

namespace K8sEscapeRoom.Api.Services.Storage;

/// <summary>
/// In-memory progress storage for local development.
/// Data is lost on restart.
/// </summary>
public class InMemoryProgressStorage : IProgressStorage
{
    // userId -> Set of completed roomIds
    private readonly ConcurrentDictionary<string, HashSet<string>> _progress = new();

    public Task<IReadOnlyList<string>> GetCompletedRoomsAsync(string userId)
    {
        if (_progress.TryGetValue(userId, out var rooms))
        {
            return Task.FromResult<IReadOnlyList<string>>(rooms.ToList());
        }
        return Task.FromResult<IReadOnlyList<string>>(Array.Empty<string>());
    }

    public Task MarkRoomCompleteAsync(string userId, string roomId)
    {
        _progress.AddOrUpdate(
            userId,
            _ => new HashSet<string> { roomId },
            (_, existing) =>
            {
                existing.Add(roomId);
                return existing;
            }
        );
        return Task.CompletedTask;
    }

    public Task<bool> IsRoomCompletedAsync(string userId, string roomId)
    {
        if (_progress.TryGetValue(userId, out var rooms))
        {
            return Task.FromResult(rooms.Contains(roomId));
        }
        return Task.FromResult(false);
    }
}
