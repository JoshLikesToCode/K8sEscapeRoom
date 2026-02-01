using System.CommandLine;
using K8sEscapeRoom.Cli.Commands;
using K8sEscapeRoom.Cli.Services;

namespace K8sEscapeRoom.Cli;

/// <summary>
/// K8sEscapeRoom CLI - A thin wrapper around the Makefile and scripts
/// for orchestrating Kubernetes escape room scenarios.
///
/// Command mapping:
///   escape cluster up        → make cluster-up
///   escape cluster down      → make cluster-down
///   escape cluster status    → make cluster-status
///   escape tools check       → make tools-check
///   escape room list         → make room-list
///   escape room apply <name> → make room-apply ROOM=<name>
///   escape room reset <name> → make room-reset ROOM=<name>
///   escape room test <name>  → make room-test ROOM=<name>
///   escape room objective <name> → make room-objective ROOM=<name>
///   escape room hint <name>  → make room-hint ROOM=<name>
///   escape room solution <name> → make room-solution ROOM=<name>
/// </summary>
public static class Program
{
    public static async Task<int> Main(string[] args)
    {
        // Find project root
        var projectRoot = ProjectLocator.FindProjectRoot();
        if (projectRoot is null)
        {
            Console.Error.WriteLine("\u001b[31mError: Could not find K8sEscapeRoom project root.\u001b[0m");
            Console.Error.WriteLine("Ensure you're running from within the project directory.");
            return 1;
        }

        // Create services
        using var processRunner = new ProcessRunner();
        var clusterService = new ClusterService(projectRoot, processRunner);
        var roomService = new RoomService(projectRoot, processRunner);

        // Build command tree
        var rootCommand = new RootCommand("K8sEscapeRoom - Debug Kubernetes failures to escape each room")
        {
            ClusterCommands.Create(clusterService),
            ToolsCommands.Create(clusterService),
            RoomCommands.Create(roomService)
        };

        // Execute
        return await rootCommand.InvokeAsync(args);
    }
}
