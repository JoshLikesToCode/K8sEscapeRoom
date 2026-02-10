using System.Diagnostics;
using System.Runtime.InteropServices;

namespace K8sEscapeRoom.Cli.Services;

/// <summary>
/// Service for checking system prerequisites and diagnosing issues.
/// </summary>
public class DoctorService
{
    private readonly string? _projectRoot;

    public DoctorService(string? projectRoot)
    {
        _projectRoot = projectRoot;
    }

    public record CheckResult(string Name, bool Passed, string? Version, string? Message, string? Hint);

    /// <summary>
    /// Run all diagnostic checks and return results.
    /// </summary>
    public async Task<List<CheckResult>> RunAllChecksAsync()
    {
        var results = new List<CheckResult>();

        // Check Docker
        results.Add(await CheckDockerAsync());

        // Check kubectl
        results.Add(await CheckKubectlAsync());

        // Check kind
        results.Add(await CheckKindAsync());

        // Check cluster connectivity
        results.Add(await CheckClusterAsync());

        // Check make (needed for room commands)
        results.Add(await CheckMakeAsync());

        // Check project root
        results.Add(CheckProjectRoot());

        return results;
    }

    private async Task<CheckResult> CheckDockerAsync()
    {
        try
        {
            var (exitCode, output) = await RunCommandAsync("docker", "version --format '{{.Server.Version}}'");
            if (exitCode == 0 && !string.IsNullOrWhiteSpace(output))
            {
                var version = output.Trim().Trim('\'');
                return new CheckResult("Docker", true, version, "Docker is running", null);
            }

            // Docker might be installed but not running
            var (checkCode, _) = await RunCommandAsync("docker", "--version");
            if (checkCode == 0)
            {
                return new CheckResult("Docker", false, null, "Docker is installed but not running",
                    GetDockerStartHint());
            }

            return new CheckResult("Docker", false, null, "Docker is not installed",
                GetDockerInstallHint());
        }
        catch
        {
            return new CheckResult("Docker", false, null, "Docker is not installed",
                GetDockerInstallHint());
        }
    }

    private async Task<CheckResult> CheckKubectlAsync()
    {
        try
        {
            var (exitCode, output) = await RunCommandAsync("kubectl", "version --client -o json");
            if (exitCode == 0)
            {
                // Parse version from JSON output
                var version = "installed";
                if (output.Contains("\"gitVersion\""))
                {
                    var start = output.IndexOf("\"gitVersion\"") + 14;
                    var end = output.IndexOf('"', start);
                    if (end > start)
                    {
                        version = output[start..end];
                    }
                }
                return new CheckResult("kubectl", true, version, "kubectl is installed", null);
            }

            return new CheckResult("kubectl", false, null, "kubectl is not installed",
                GetKubectlInstallHint());
        }
        catch
        {
            return new CheckResult("kubectl", false, null, "kubectl is not installed",
                GetKubectlInstallHint());
        }
    }

    private async Task<CheckResult> CheckKindAsync()
    {
        try
        {
            var (exitCode, output) = await RunCommandAsync("kind", "version");
            if (exitCode == 0)
            {
                var version = output.Trim().Split(' ').LastOrDefault() ?? "installed";
                return new CheckResult("kind", true, version, "kind is installed", null);
            }

            return new CheckResult("kind", false, null, "kind is not installed",
                GetKindInstallHint());
        }
        catch
        {
            return new CheckResult("kind", false, null, "kind is not installed",
                GetKindInstallHint());
        }
    }

    private async Task<CheckResult> CheckClusterAsync()
    {
        try
        {
            // First check if we have a kubeconfig context
            var (contextCode, context) = await RunCommandAsync("kubectl", "config current-context");
            if (contextCode != 0)
            {
                return new CheckResult("Cluster", false, null, "No Kubernetes context configured",
                    "Run: escape cluster up (or: kind create cluster --name k8s-escape-room)");
            }

            var contextName = context.Trim();

            // Check if cluster is reachable
            var (exitCode, _) = await RunCommandAsync("kubectl", "cluster-info --request-timeout=5s");
            if (exitCode == 0)
            {
                return new CheckResult("Cluster", true, contextName, $"Connected to cluster: {contextName}", null);
            }

            return new CheckResult("Cluster", false, contextName, $"Cluster '{contextName}' is not reachable",
                "Start your cluster or run: escape cluster up");
        }
        catch
        {
            return new CheckResult("Cluster", false, null, "Cannot check cluster status",
                "Ensure kubectl is configured correctly");
        }
    }

    private async Task<CheckResult> CheckMakeAsync()
    {
        try
        {
            var (exitCode, output) = await RunCommandAsync("make", "--version");
            if (exitCode == 0)
            {
                var firstLine = output.Split('\n').FirstOrDefault() ?? "installed";
                var version = firstLine.Contains("GNU Make") ? firstLine : "installed";
                return new CheckResult("make", true, version, "make is installed", null);
            }

            return new CheckResult("make", false, null, "make is not installed",
                GetMakeInstallHint());
        }
        catch
        {
            return new CheckResult("make", false, null, "make is not installed",
                GetMakeInstallHint());
        }
    }

    private CheckResult CheckProjectRoot()
    {
        if (_projectRoot != null && Directory.Exists(_projectRoot))
        {
            var roomsDir = Path.Combine(_projectRoot, "rooms");
            var roomCount = Directory.Exists(roomsDir)
                ? Directory.GetDirectories(roomsDir).Count(d => Path.GetFileName(d).StartsWith("room-"))
                : 0;

            return new CheckResult("Project", true, $"{roomCount} rooms",
                $"Project found at: {_projectRoot}", null);
        }

        return new CheckResult("Project", false, null, "K8sEscapeRoom project not found",
            "Clone the repo: git clone https://github.com/JoshLikesToCode/K8sEscapeRoom.git");
    }

    private static async Task<(int ExitCode, string Output)> RunCommandAsync(string command, string arguments)
    {
        var psi = new ProcessStartInfo
        {
            FileName = command,
            Arguments = arguments,
            RedirectStandardOutput = true,
            RedirectStandardError = true,
            UseShellExecute = false,
            CreateNoWindow = true
        };

        using var process = Process.Start(psi);
        if (process == null)
        {
            return (-1, "");
        }

        var output = await process.StandardOutput.ReadToEndAsync();
        await process.WaitForExitAsync();
        return (process.ExitCode, output);
    }

    // Platform-specific hints
    private static string GetDockerInstallHint()
    {
        if (RuntimeInformation.IsOSPlatform(OSPlatform.OSX))
            return "Install Docker Desktop: https://docs.docker.com/desktop/install/mac-install/";
        if (RuntimeInformation.IsOSPlatform(OSPlatform.Windows))
            return "Install Docker Desktop: https://docs.docker.com/desktop/install/windows-install/";
        return "Install Docker: https://docs.docker.com/engine/install/";
    }

    private static string GetDockerStartHint()
    {
        if (RuntimeInformation.IsOSPlatform(OSPlatform.OSX) || RuntimeInformation.IsOSPlatform(OSPlatform.Windows))
            return "Start Docker Desktop from your applications";
        return "Start Docker: sudo systemctl start docker";
    }

    private static string GetKubectlInstallHint()
    {
        if (RuntimeInformation.IsOSPlatform(OSPlatform.OSX))
            return "Install: brew install kubectl";
        if (RuntimeInformation.IsOSPlatform(OSPlatform.Windows))
            return "Install: winget install Kubernetes.kubectl";
        return "Install: https://kubernetes.io/docs/tasks/tools/install-kubectl-linux/";
    }

    private static string GetKindInstallHint()
    {
        if (RuntimeInformation.IsOSPlatform(OSPlatform.OSX))
            return "Install: brew install kind";
        if (RuntimeInformation.IsOSPlatform(OSPlatform.Windows))
            return "Install: winget install Kubernetes.kind";
        return "Install: go install sigs.k8s.io/kind@latest (or download from GitHub releases)";
    }

    private static string GetMakeInstallHint()
    {
        if (RuntimeInformation.IsOSPlatform(OSPlatform.OSX))
            return "Install: xcode-select --install";
        if (RuntimeInformation.IsOSPlatform(OSPlatform.Windows))
            return "Install: winget install GnuWin32.Make (or use WSL)";
        return "Install: sudo apt-get install build-essential";
    }
}
