namespace K8sEscapeRoom.Cli.Services;

/// <summary>
/// Service for discovering and interacting with escape rooms.
/// </summary>
public class RoomService
{
    private readonly string _roomsDirectory;
    private readonly string _projectRoot;
    private readonly ProcessRunner _processRunner;

    public RoomService(string projectRoot, ProcessRunner processRunner)
    {
        _projectRoot = projectRoot;
        _processRunner = processRunner;
        _roomsDirectory = Path.Combine(projectRoot, "rooms");
    }

    /// <summary>
    /// Gets all available room names.
    /// Rooms are directories under /rooms that start with "room-".
    /// </summary>
    public IReadOnlyList<string> GetRoomNames()
    {
        return DiscoverRooms(_roomsDirectory);
    }

    /// <summary>
    /// Discovers rooms in the specified directory.
    /// Includes both room-* and boss-* directories.
    /// </summary>
    public static IReadOnlyList<string> DiscoverRooms(string roomsDirectory)
    {
        if (!Directory.Exists(roomsDirectory))
        {
            return [];
        }

        return Directory.GetDirectories(roomsDirectory)
            .Select(Path.GetFileName)
            .Where(name => name is not null && (name.StartsWith("room-") || name.StartsWith("boss-")))
            .Cast<string>()
            .OrderBy(name => name)
            .ToList();
    }

    /// <summary>
    /// Checks if a room exists.
    /// </summary>
    public bool RoomExists(string roomName)
    {
        return Directory.Exists(GetRoomPath(roomName));
    }

    /// <summary>
    /// Gets the full path to a room directory.
    /// </summary>
    public string GetRoomPath(string roomName)
    {
        return Path.Combine(_roomsDirectory, roomName);
    }

    /// <summary>
    /// Gets the content of a room's documentation file.
    /// </summary>
    public string? GetRoomDocument(string roomName, string documentName)
    {
        var filePath = Path.Combine(_roomsDirectory, roomName, documentName);
        return File.Exists(filePath) ? File.ReadAllText(filePath) : null;
    }

    /// <summary>
    /// Gets the room's objective (OBJECTIVE.md or INCIDENT.md for boss rooms).
    /// </summary>
    public string? GetObjective(string roomName) =>
        GetRoomDocument(roomName, "OBJECTIVE.md") ?? GetRoomDocument(roomName, "INCIDENT.md");

    /// <summary>
    /// Gets the room's hints.
    /// </summary>
    public string? GetHints(string roomName) => GetRoomDocument(roomName, "HINTS.md");

    /// <summary>
    /// Gets the room's solution.
    /// </summary>
    public string? GetSolution(string roomName) => GetRoomDocument(roomName, "SOLUTION.md");

    /// <summary>
    /// Extracts a specific hint level from hints content.
    /// </summary>
    public static string? ExtractHintLevel(string content, int level)
    {
        var lines = content.Split('\n');
        var inTargetSection = false;
        var result = new List<string>();

        foreach (var line in lines)
        {
            if (line.StartsWith("## Hint Level "))
            {
                if (line.Contains($"Level {level}"))
                {
                    inTargetSection = true;
                    result.Add(line);
                }
                else if (inTargetSection)
                {
                    break; // Reached next section
                }
            }
            else if (inTargetSection)
            {
                result.Add(line);
            }
        }

        return result.Count > 0 ? string.Join('\n', result).Trim() : null;
    }

    /// <summary>
    /// Extracts the first content line (non-header) from markdown.
    /// </summary>
    public static string? ExtractSummary(string? content)
    {
        if (string.IsNullOrEmpty(content))
            return null;

        return content.Split('\n')
            .Select(l => l.Trim())
            .FirstOrDefault(l => !string.IsNullOrEmpty(l) && !l.StartsWith('#'));
    }

    // =========================================================================
    // Commands - These map 1:1 to Makefile targets
    // =========================================================================

    /// <summary>
    /// Applies a room's broken state.
    /// Maps to: make room-apply ROOM=...
    /// </summary>
    public Task<ProcessRunner.ProcessResult> ApplyRoomAsync(
        string roomName, CancellationToken ct = default)
    {
        return _processRunner.RunMakeAsync("room-apply", _projectRoot,
            new Dictionary<string, string> { ["ROOM"] = roomName }, ct);
    }

    /// <summary>
    /// Resets a room (removes its resources).
    /// Maps to: make room-reset ROOM=...
    /// </summary>
    public Task<ProcessRunner.ProcessResult> ResetRoomAsync(
        string roomName, CancellationToken ct = default)
    {
        return _processRunner.RunMakeAsync("room-reset", _projectRoot,
            new Dictionary<string, string> { ["ROOM"] = roomName }, ct);
    }

    /// <summary>
    /// Runs tests for a room.
    /// Maps to: make room-test ROOM=...
    /// </summary>
    public Task<ProcessRunner.ProcessResult> TestRoomAsync(
        string roomName, CancellationToken ct = default)
    {
        return _processRunner.RunMakeAsync("room-test", _projectRoot,
            new Dictionary<string, string> { ["ROOM"] = roomName }, ct);
    }

    /// <summary>
    /// Verifies that a room has been escaped (fixed).
    /// Maps to: make room-verify ROOM=...
    /// </summary>
    public Task<ProcessRunner.ProcessResult> VerifyRoomAsync(
        string roomName, CancellationToken ct = default)
    {
        return _processRunner.RunMakeAsync("room-verify", _projectRoot,
            new Dictionary<string, string> { ["ROOM"] = roomName }, ct);
    }
}
