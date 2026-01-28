using System.CommandLine;
using K8sEscapeRoom.Cli.Commands;
using K8sEscapeRoom.Cli.Services;

namespace K8sEscapeRoom.Cli;

/// <summary>
/// K8sEscapeRoom CLI - A thin wrapper around the Makefile and scripts
/// for orchestrating Kubernetes escape room scenarios.
/// </summary>
public class Program
{
    public static async Task<int> Main(string[] args)
    {
        var rootCommand = new RootCommand("K8sEscapeRoom - Debug Kubernetes failures to escape each room");

        var scriptRunner = new ScriptRunner();
        var roomService = new RoomService(scriptRunner);

        // Add subcommands
        rootCommand.AddCommand(ClusterCommands.Create(scriptRunner));
        rootCommand.AddCommand(RoomCommands.Create(roomService));

        return await rootCommand.InvokeAsync(args);
    }
}
