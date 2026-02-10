namespace K8sEscapeRoom.Api.Models;

/// <summary>
/// Represents an authenticated user
/// </summary>
public record User(
    string Id,
    string Username,
    string Provider
);

/// <summary>
/// User info with progress data
/// </summary>
public record UserProgress(
    User User,
    IReadOnlyList<string> CompletedRooms
);
