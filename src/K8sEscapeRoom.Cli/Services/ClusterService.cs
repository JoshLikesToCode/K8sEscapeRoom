namespace K8sEscapeRoom.Cli.Services;

/// <summary>
/// Service for managing the Kubernetes cluster lifecycle.
/// </summary>
public class ClusterService
{
    private readonly string _projectRoot;
    private readonly ProcessRunner _processRunner;

    public ClusterService(string projectRoot, ProcessRunner processRunner)
    {
        _projectRoot = projectRoot;
        _processRunner = processRunner;
    }

    // =========================================================================
    // Commands - These map 1:1 to Makefile targets
    // =========================================================================

    /// <summary>
    /// Creates the kind cluster.
    /// Maps to: make cluster-up
    /// </summary>
    public Task<ProcessRunner.ProcessResult> UpAsync(CancellationToken ct = default)
    {
        return _processRunner.RunMakeAsync("cluster-up", _projectRoot, cancellationToken: ct);
    }

    /// <summary>
    /// Deletes the kind cluster.
    /// Maps to: make cluster-down
    /// </summary>
    public Task<ProcessRunner.ProcessResult> DownAsync(CancellationToken ct = default)
    {
        return _processRunner.RunMakeAsync("cluster-down", _projectRoot, cancellationToken: ct);
    }

    /// <summary>
    /// Shows cluster status.
    /// Maps to: make cluster-status
    /// </summary>
    public Task<ProcessRunner.ProcessResult> StatusAsync(CancellationToken ct = default)
    {
        return _processRunner.RunMakeAsync("cluster-status", _projectRoot, cancellationToken: ct);
    }

    /// <summary>
    /// Checks that required tools are installed.
    /// Maps to: make tools-check
    /// </summary>
    public Task<ProcessRunner.ProcessResult> ToolsCheckAsync(CancellationToken ct = default)
    {
        return _processRunner.RunMakeAsync("tools-check", _projectRoot, cancellationToken: ct);
    }
}
