using System.CommandLine;
using K8sEscapeRoom.Cli.Services;

namespace K8sEscapeRoom.Cli.Commands;

/// <summary>
/// Commands for interacting with escape rooms.
/// </summary>
public static class RoomCommands
{
    public static Command Create(RoomService roomService)
    {
        var roomCommand = new Command("room", "Manage escape rooms");

        // room list
        var listCommand = new Command("list", "List all available rooms");
        listCommand.SetHandler(() =>
        {
            Console.WriteLine("Available Escape Rooms:");
            Console.WriteLine();

            foreach (var room in roomService.GetRoomNames())
            {
                var objective = roomService.GetObjective(room);
                var summary = ExtractFirstContentLine(objective);

                Console.WriteLine($"  {room}");
                if (!string.IsNullOrEmpty(summary))
                {
                    Console.WriteLine($"    {summary}");
                }
                Console.WriteLine();
            }
        });

        // room apply <name>
        var applyCommand = new Command("apply", "Apply a room's broken state");
        var applyRoomArg = new Argument<string>("name", "The room name");
        applyCommand.AddArgument(applyRoomArg);
        applyCommand.SetHandler(async (string roomName) =>
        {
            if (!roomService.RoomExists(roomName))
            {
                Console.Error.WriteLine($"Room '{roomName}' not found.");
                Console.Error.WriteLine("Run 'escape room list' to see available rooms.");
                Environment.ExitCode = 1;
                return;
            }

            var exitCode = await roomService.ApplyRoomAsync(roomName);
            Environment.ExitCode = exitCode;
        }, applyRoomArg);

        // room reset <name>
        var resetCommand = new Command("reset", "Reset a room (remove its resources)");
        var resetRoomArg = new Argument<string>("name", "The room name");
        resetCommand.AddArgument(resetRoomArg);
        resetCommand.SetHandler(async (string roomName) =>
        {
            if (!roomService.RoomExists(roomName))
            {
                Console.Error.WriteLine($"Room '{roomName}' not found.");
                Environment.ExitCode = 1;
                return;
            }

            var exitCode = await roomService.ResetRoomAsync(roomName);
            Environment.ExitCode = exitCode;
        }, resetRoomArg);

        // room objective <name>
        var objectiveCommand = new Command("objective", "Show a room's objective");
        var objectiveRoomArg = new Argument<string>("name", "The room name");
        objectiveCommand.AddArgument(objectiveRoomArg);
        objectiveCommand.SetHandler((string roomName) =>
        {
            var content = roomService.GetObjective(roomName);
            if (content == null)
            {
                Console.Error.WriteLine($"Room '{roomName}' not found or has no OBJECTIVE.md.");
                Environment.ExitCode = 1;
                return;
            }
            Console.WriteLine(content);
        }, objectiveRoomArg);

        // room hint <name> [--level]
        var hintCommand = new Command("hint", "Show hints for a room");
        var hintRoomArg = new Argument<string>("name", "The room name");
        var levelOption = new Option<int?>("--level", "Hint level (1-4)");
        levelOption.AddAlias("-l");
        hintCommand.AddArgument(hintRoomArg);
        hintCommand.AddOption(levelOption);
        hintCommand.SetHandler((string roomName, int? level) =>
        {
            var content = roomService.GetHints(roomName);
            if (content == null)
            {
                Console.Error.WriteLine($"Room '{roomName}' not found or has no HINTS.md.");
                Environment.ExitCode = 1;
                return;
            }

            if (level.HasValue)
            {
                // Extract specific hint level
                var hintSection = ExtractHintLevel(content, level.Value);
                if (hintSection != null)
                {
                    Console.WriteLine(hintSection);
                }
                else
                {
                    Console.Error.WriteLine($"Hint level {level.Value} not found.");
                    Environment.ExitCode = 1;
                }
            }
            else
            {
                Console.WriteLine(content);
            }
        }, hintRoomArg, levelOption);

        // room solution <name>
        var solutionCommand = new Command("solution", "Show the solution for a room");
        var solutionRoomArg = new Argument<string>("name", "The room name");
        solutionCommand.AddArgument(solutionRoomArg);
        solutionCommand.SetHandler((string roomName) =>
        {
            var content = roomService.GetSolution(roomName);
            if (content == null)
            {
                Console.Error.WriteLine($"Room '{roomName}' not found or has no SOLUTION.md.");
                Environment.ExitCode = 1;
                return;
            }
            Console.WriteLine(content);
        }, solutionRoomArg);

        roomCommand.AddCommand(listCommand);
        roomCommand.AddCommand(applyCommand);
        roomCommand.AddCommand(resetCommand);
        roomCommand.AddCommand(objectiveCommand);
        roomCommand.AddCommand(hintCommand);
        roomCommand.AddCommand(solutionCommand);

        return roomCommand;
    }

    /// <summary>
    /// Extracts the first non-header, non-empty line from markdown content.
    /// </summary>
    private static string? ExtractFirstContentLine(string? content)
    {
        if (string.IsNullOrEmpty(content))
            return null;

        var lines = content.Split('\n')
            .Select(l => l.Trim())
            .Where(l => !string.IsNullOrEmpty(l) && !l.StartsWith('#'));

        return lines.FirstOrDefault();
    }

    /// <summary>
    /// Extracts a specific hint level from the hints markdown.
    /// </summary>
    private static string? ExtractHintLevel(string content, int level)
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
                    // Reached next section, stop
                    break;
                }
            }
            else if (inTargetSection)
            {
                result.Add(line);
            }
        }

        return result.Count > 0 ? string.Join('\n', result).Trim() : null;
    }
}
