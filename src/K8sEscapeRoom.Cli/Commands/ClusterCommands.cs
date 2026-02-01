using System.CommandLine;
using System.CommandLine.Invocation;
using K8sEscapeRoom.Cli.Services;

namespace K8sEscapeRoom.Cli.Commands;

/// <summary>
/// Commands for managing the kind cluster lifecycle.
/// Maps 1:1 to Makefile cluster-* targets.
/// </summary>
public static class ClusterCommands
{
    public static Command Create(ClusterService clusterService)
    {
        var clusterCommand = new Command("cluster", "Manage the Kubernetes cluster")
        {
            CreateUpCommand(clusterService),
            CreateDownCommand(clusterService),
            CreateStatusCommand(clusterService)
        };

        return clusterCommand;
    }

    /// <summary>
    /// escape cluster up → make cluster-up
    /// </summary>
    private static Command CreateUpCommand(ClusterService clusterService)
    {
        var command = new Command("up", "Create the kind cluster");

        command.SetHandler(async () =>
        {
            var result = await clusterService.UpAsync();
            Environment.ExitCode = result.ExitCode;
        });

        return command;
    }

    /// <summary>
    /// escape cluster down → make cluster-down
    /// </summary>
    private static Command CreateDownCommand(ClusterService clusterService)
    {
        var command = new Command("down", "Delete the kind cluster");

        command.SetHandler(async () =>
        {
            var result = await clusterService.DownAsync();
            Environment.ExitCode = result.ExitCode;
        });

        return command;
    }

    /// <summary>
    /// escape cluster status → make cluster-status
    /// </summary>
    private static Command CreateStatusCommand(ClusterService clusterService)
    {
        var command = new Command("status", "Show cluster status");

        command.SetHandler(async () =>
        {
            var result = await clusterService.StatusAsync();
            Environment.ExitCode = result.ExitCode;
        });

        return command;
    }
}
