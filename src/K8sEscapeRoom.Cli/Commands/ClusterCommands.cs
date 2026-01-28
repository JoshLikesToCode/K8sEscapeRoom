using System.CommandLine;
using K8sEscapeRoom.Cli.Services;

namespace K8sEscapeRoom.Cli.Commands;

/// <summary>
/// Commands for managing the kind cluster lifecycle.
/// </summary>
public static class ClusterCommands
{
    public static Command Create(ScriptRunner scriptRunner)
    {
        var clusterCommand = new Command("cluster", "Manage the Kubernetes cluster");

        // cluster up
        var upCommand = new Command("up", "Create the kind cluster");
        upCommand.SetHandler(async () =>
        {
            var exitCode = await scriptRunner.RunMakeTargetAsync("cluster-up");
            Environment.ExitCode = exitCode;
        });

        // cluster down
        var downCommand = new Command("down", "Delete the kind cluster");
        downCommand.SetHandler(async () =>
        {
            var exitCode = await scriptRunner.RunMakeTargetAsync("cluster-down");
            Environment.ExitCode = exitCode;
        });

        // cluster status
        var statusCommand = new Command("status", "Show cluster status");
        statusCommand.SetHandler(async () =>
        {
            var exitCode = await scriptRunner.RunMakeTargetAsync("cluster-status");
            Environment.ExitCode = exitCode;
        });

        clusterCommand.AddCommand(upCommand);
        clusterCommand.AddCommand(downCommand);
        clusterCommand.AddCommand(statusCommand);

        return clusterCommand;
    }
}
