using System.CommandLine;
using K8sEscapeRoom.Cli.Commands;
using K8sEscapeRoom.Cli.Services;

namespace K8sEscapeRoom.Cli;

/// <summary>
/// K8sEscapeRoom CLI - A thin wrapper around the Makefile and scripts
/// for orchestrating Kubernetes escape room scenarios.
///
/// Command mapping:
///   escape doctor            → Check prerequisites and diagnose issues
///   escape quickstart        → Guided tutorial to get started
///   escape cluster up        → make cluster-up
///   escape cluster down      → make cluster-down
///   escape cluster status    → make cluster-status
///   escape tools check       → make tools-check
///   escape room list         → make room-list
///   escape room apply <name> → make room-apply ROOM=<name>
///   escape room reset <name> → make room-reset ROOM=<name>
///   escape room test <name>  → make room-test ROOM=<name>
///   escape room verify <name> → make room-verify ROOM=<name>
///   escape room proof <name> --nonce <nonce> → Generate proof token
///   escape room objective <name> → make room-objective ROOM=<name>
///   escape room hint <name>  → make room-hint ROOM=<name>
///   escape room solution <name> → make room-solution ROOM=<name>
/// </summary>
public static class Program
{
    public static async Task<int> Main(string[] args)
    {
        // Find project root (may be null if running standalone)
        var projectRoot = ProjectLocator.FindProjectRoot();

        // Create services
        var doctorService = new DoctorService(projectRoot);

        // For commands that require project root, we'll check and fail gracefully
        ProcessRunner? processRunner = null;
        ClusterService? clusterService = null;
        RoomService? roomService = null;

        if (projectRoot is not null)
        {
            processRunner = new ProcessRunner();
            clusterService = new ClusterService(projectRoot, processRunner);
            roomService = new RoomService(projectRoot, processRunner);
        }

        // Build command tree
        var rootCommand = new RootCommand("K8sEscapeRoom - Debug Kubernetes failures to escape each room")
        {
            DoctorCommands.Create(doctorService)
        };

        // Add commands that require project root
        if (clusterService is not null && roomService is not null)
        {
            rootCommand.Add(QuickstartCommands.Create(doctorService, clusterService, roomService));
            rootCommand.Add(ClusterCommands.Create(clusterService));
            rootCommand.Add(ToolsCommands.Create(clusterService));
            rootCommand.Add(RoomCommands.Create(roomService));
        }
        else
        {
            // Add placeholder commands that explain the issue
            rootCommand.Add(CreateProjectRequiredCommand("quickstart"));
            rootCommand.Add(CreateProjectRequiredCommand("cluster"));
            rootCommand.Add(CreateProjectRequiredCommand("tools"));
            rootCommand.Add(CreateProjectRequiredCommand("room"));
        }

        // Execute
        var result = await rootCommand.InvokeAsync(args);

        // Cleanup
        processRunner?.Dispose();

        return result;
    }

    private static Command CreateProjectRequiredCommand(string name)
    {
        var command = new Command(name, $"{name} commands (requires project directory)");
        command.SetHandler(() =>
        {
            Console.Error.WriteLine("\u001b[31mError: Could not find K8sEscapeRoom project root.\u001b[0m");
            Console.Error.WriteLine();
            Console.Error.WriteLine("To use this command, either:");
            Console.Error.WriteLine("  1. Run from within the K8sEscapeRoom project directory");
            Console.Error.WriteLine("  2. Clone the repo: git clone https://github.com/JoshLikesToCode/K8sEscapeRoom.git");
            Console.Error.WriteLine();
            Console.Error.WriteLine("Run \u001b[36mescape doctor\u001b[0m to check your setup.");
            Environment.ExitCode = 1;
        });
        return command;
    }
}
