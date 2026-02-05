using System.CommandLine;
using K8sEscapeRoom.Cli.Services;

namespace K8sEscapeRoom.Cli.Commands;

/// <summary>
/// Commands for interacting with escape rooms.
/// Maps 1:1 to Makefile room-* targets.
/// </summary>
public static class RoomCommands
{
    public static Command Create(RoomService roomService)
    {
        var roomCommand = new Command("room", "Manage escape rooms")
        {
            CreateListCommand(roomService),
            CreateApplyCommand(roomService),
            CreateResetCommand(roomService),
            CreateTestCommand(roomService),
            CreateVerifyCommand(roomService),
            CreateObjectiveCommand(roomService),
            CreateHintCommand(roomService),
            CreateSolutionCommand(roomService)
        };

        return roomCommand;
    }

    /// <summary>
    /// escape room list → make room-list
    /// </summary>
    private static Command CreateListCommand(RoomService roomService)
    {
        var command = new Command("list", "List all available rooms");

        command.SetHandler(() =>
        {
            var rooms = roomService.GetRoomNames();

            if (rooms.Count == 0)
            {
                Console.WriteLine("No rooms found.");
                return;
            }

            Console.WriteLine("\u001b[36mAvailable Escape Rooms:\u001b[0m");
            Console.WriteLine();

            foreach (var room in rooms)
            {
                var objective = roomService.GetObjective(room);
                var summary = RoomService.ExtractSummary(objective);

                Console.WriteLine($"  \u001b[32m{room}\u001b[0m");
                if (!string.IsNullOrEmpty(summary))
                {
                    Console.WriteLine($"    {summary}");
                }
                Console.WriteLine();
            }
        });

        return command;
    }

    /// <summary>
    /// escape room apply <name> → make room-apply ROOM=<name>
    /// </summary>
    private static Command CreateApplyCommand(RoomService roomService)
    {
        var command = new Command("apply", "Apply a room's broken state (enter the room)");
        var roomArg = new Argument<string>("name", "The room name (e.g., room-crashloop-env)");
        command.AddArgument(roomArg);

        command.SetHandler(async (string roomName) =>
        {
            if (!ValidateRoom(roomService, roomName))
                return;

            var result = await roomService.ApplyRoomAsync(roomName);
            Environment.ExitCode = result.ExitCode;
        }, roomArg);

        return command;
    }

    /// <summary>
    /// escape room reset <name> → make room-reset ROOM=<name>
    /// </summary>
    private static Command CreateResetCommand(RoomService roomService)
    {
        var command = new Command("reset", "Reset a room (remove its resources)");
        var roomArg = new Argument<string>("name", "The room name");
        command.AddArgument(roomArg);

        command.SetHandler(async (string roomName) =>
        {
            if (!ValidateRoom(roomService, roomName))
                return;

            var result = await roomService.ResetRoomAsync(roomName);
            Environment.ExitCode = result.ExitCode;
        }, roomArg);

        return command;
    }

    /// <summary>
    /// escape room test <name> → make room-test ROOM=<name>
    /// </summary>
    private static Command CreateTestCommand(RoomService roomService)
    {
        var command = new Command("test", "Run tests to validate a room is in expected failure state");
        var roomArg = new Argument<string>("name", "The room name");
        command.AddArgument(roomArg);

        command.SetHandler(async (string roomName) =>
        {
            if (!ValidateRoom(roomService, roomName))
                return;

            var result = await roomService.TestRoomAsync(roomName);
            Environment.ExitCode = result.ExitCode;
        }, roomArg);

        return command;
    }

    /// <summary>
    /// escape room verify <name> → make room-verify ROOM=<name>
    /// Validates that the user has successfully escaped (fixed the room).
    /// </summary>
    private static Command CreateVerifyCommand(RoomService roomService)
    {
        var command = new Command("verify", "Verify you've escaped (fixed the room)");
        var roomArg = new Argument<string>("name", "The room name");
        command.AddArgument(roomArg);

        command.SetHandler(async (string roomName) =>
        {
            if (!ValidateRoom(roomService, roomName))
                return;

            var result = await roomService.VerifyRoomAsync(roomName);
            Environment.ExitCode = result.ExitCode;
        }, roomArg);

        return command;
    }

    /// <summary>
    /// escape room objective <name> → make room-objective ROOM=<name>
    /// </summary>
    private static Command CreateObjectiveCommand(RoomService roomService)
    {
        var command = new Command("objective", "Show a room's objective (what you need to achieve)");
        var roomArg = new Argument<string>("name", "The room name");
        command.AddArgument(roomArg);

        command.SetHandler((string roomName) =>
        {
            if (!ValidateRoom(roomService, roomName))
                return;

            var content = roomService.GetObjective(roomName);
            if (content is null)
            {
                WriteError($"OBJECTIVE.md not found for room '{roomName}'.");
                Environment.ExitCode = 1;
                return;
            }

            Console.WriteLine(content);
        }, roomArg);

        return command;
    }

    /// <summary>
    /// escape room hint <name> [--level N] → make room-hint ROOM=<name>
    /// </summary>
    private static Command CreateHintCommand(RoomService roomService)
    {
        var command = new Command("hint", "Show hints for a room");
        var roomArg = new Argument<string>("name", "The room name");
        var levelOption = new Option<int?>(
            aliases: ["--level", "-l"],
            description: "Show only a specific hint level (1-4)");

        command.AddArgument(roomArg);
        command.AddOption(levelOption);

        command.SetHandler((string roomName, int? level) =>
        {
            if (!ValidateRoom(roomService, roomName))
                return;

            var content = roomService.GetHints(roomName);
            if (content is null)
            {
                WriteError($"HINTS.md not found for room '{roomName}'.");
                Environment.ExitCode = 1;
                return;
            }

            if (level.HasValue)
            {
                var hintSection = RoomService.ExtractHintLevel(content, level.Value);
                if (hintSection is not null)
                {
                    Console.WriteLine(hintSection);
                }
                else
                {
                    WriteError($"Hint level {level.Value} not found. Valid levels are 1-4.");
                    Environment.ExitCode = 1;
                }
            }
            else
            {
                Console.WriteLine(content);
            }
        }, roomArg, levelOption);

        return command;
    }

    /// <summary>
    /// escape room solution <name> → make room-solution ROOM=<name>
    /// </summary>
    private static Command CreateSolutionCommand(RoomService roomService)
    {
        var command = new Command("solution", "Show the full solution for a room (spoilers!)");
        var roomArg = new Argument<string>("name", "The room name");
        command.AddArgument(roomArg);

        command.SetHandler((string roomName) =>
        {
            if (!ValidateRoom(roomService, roomName))
                return;

            var content = roomService.GetSolution(roomName);
            if (content is null)
            {
                WriteError($"SOLUTION.md not found for room '{roomName}'.");
                Environment.ExitCode = 1;
                return;
            }

            Console.WriteLine(content);
        }, roomArg);

        return command;
    }

    // =========================================================================
    // Helpers
    // =========================================================================

    private static bool ValidateRoom(RoomService roomService, string roomName)
    {
        if (roomService.RoomExists(roomName))
            return true;

        WriteError($"Room '{roomName}' not found.");
        Console.Error.WriteLine();
        Console.Error.WriteLine("Available rooms:");

        foreach (var room in roomService.GetRoomNames())
        {
            Console.Error.WriteLine($"  {room}");
        }

        Console.Error.WriteLine();
        Console.Error.WriteLine("Run 'escape room list' for details.");

        Environment.ExitCode = 1;
        return false;
    }

    private static void WriteError(string message)
    {
        Console.Error.WriteLine($"\u001b[31mError: {message}\u001b[0m");
    }
}
