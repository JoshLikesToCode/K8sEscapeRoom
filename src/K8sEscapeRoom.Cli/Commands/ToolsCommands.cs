using System.CommandLine;
using K8sEscapeRoom.Cli.Services;

namespace K8sEscapeRoom.Cli.Commands;

/// <summary>
/// Commands for checking tool prerequisites.
/// </summary>
public static class ToolsCommands
{
    /// <summary>
    /// escape tools check → make tools-check
    /// </summary>
    public static Command Create(ClusterService clusterService)
    {
        var toolsCommand = new Command("tools", "Manage tool prerequisites")
        {
            CreateCheckCommand(clusterService)
        };

        return toolsCommand;
    }

    private static Command CreateCheckCommand(ClusterService clusterService)
    {
        var command = new Command("check", "Verify that required tools are installed");

        command.SetHandler(async () =>
        {
            var result = await clusterService.ToolsCheckAsync();
            Environment.ExitCode = result.ExitCode;
        });

        return command;
    }
}
