namespace K8sEscapeRoom.Cli.Services;

/// <summary>
/// Service for discovering and interacting with escape rooms.
/// </summary>
public class RoomService
{
    private readonly ScriptRunner _scriptRunner;
    private readonly string _roomsDirectory;

    public RoomService(ScriptRunner scriptRunner)
    {
        _scriptRunner = scriptRunner;
        _roomsDirectory = Path.Combine(scriptRunner.ProjectRoot, "rooms");
    }

    /// <summary>
    /// Gets all available room names.
    /// </summary>
    public IEnumerable<string> GetRoomNames()
    {
        if (!Directory.Exists(_roomsDirectory))
        {
            return Enumerable.Empty<string>();
        }

        return Directory.GetDirectories(_roomsDirectory)
            .Select(Path.GetFileName)
            .Where(name => name != null && name.StartsWith("room-"))
            .Cast<string>()
            .OrderBy(name => name);
    }

    /// <summary>
    /// Checks if a room exists.
    /// </summary>
    public bool RoomExists(string roomName)
    {
        return Directory.Exists(Path.Combine(_roomsDirectory, roomName));
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
    /// Gets the room's objective.
    /// </summary>
    public string? GetObjective(string roomName) => GetRoomDocument(roomName, "OBJECTIVE.md");

    /// <summary>
    /// Gets the room's hints.
    /// </summary>
    public string? GetHints(string roomName) => GetRoomDocument(roomName, "HINTS.md");

    /// <summary>
    /// Gets the room's solution.
    /// </summary>
    public string? GetSolution(string roomName) => GetRoomDocument(roomName, "SOLUTION.md");

    /// <summary>
    /// Applies a room's broken state.
    /// </summary>
    public Task<int> ApplyRoomAsync(string roomName)
    {
        return _scriptRunner.RunMakeTargetAsync("room-apply", new Dictionary<string, string>
        {
            ["ROOM"] = roomName
        });
    }

    /// <summary>
    /// Resets a room (removes its resources).
    /// </summary>
    public Task<int> ResetRoomAsync(string roomName)
    {
        return _scriptRunner.RunMakeTargetAsync("room-reset", new Dictionary<string, string>
        {
            ["ROOM"] = roomName
        });
    }
}
