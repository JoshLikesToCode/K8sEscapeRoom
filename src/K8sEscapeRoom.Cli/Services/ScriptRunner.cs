using System.Diagnostics;

namespace K8sEscapeRoom.Cli.Services;

/// <summary>
/// Executes shell commands and Makefile targets.
/// This service is intentionally thin - it delegates to existing scripts
/// rather than reimplementing orchestration logic.
/// </summary>
public class ScriptRunner
{
    private readonly string _projectRoot;

    public ScriptRunner()
    {
        // Find the project root by looking for the Makefile
        _projectRoot = FindProjectRoot()
            ?? throw new InvalidOperationException(
                "Could not find K8sEscapeRoom project root. " +
                "Ensure you're running from within the project directory.");
    }

    public string ProjectRoot => _projectRoot;

    /// <summary>
    /// Runs a Makefile target with optional variables.
    /// </summary>
    public async Task<int> RunMakeTargetAsync(string target, Dictionary<string, string>? variables = null)
    {
        var args = target;
        if (variables != null)
        {
            foreach (var (key, value) in variables)
            {
                args += $" {key}={value}";
            }
        }

        return await RunCommandAsync("make", args, _projectRoot);
    }

    /// <summary>
    /// Runs a script from the scripts directory.
    /// </summary>
    public async Task<int> RunScriptAsync(string scriptName, params string[] args)
    {
        var scriptPath = Path.Combine(_projectRoot, "scripts", scriptName);
        if (!File.Exists(scriptPath))
        {
            Console.Error.WriteLine($"Script not found: {scriptPath}");
            return 1;
        }

        var arguments = string.Join(" ", args.Select(a => $"\"{a}\""));
        return await RunCommandAsync("bash", $"\"{scriptPath}\" {arguments}", _projectRoot);
    }

    /// <summary>
    /// Runs a command and streams output to console.
    /// </summary>
    private static async Task<int> RunCommandAsync(string command, string arguments, string workingDirectory)
    {
        var startInfo = new ProcessStartInfo
        {
            FileName = command,
            Arguments = arguments,
            WorkingDirectory = workingDirectory,
            UseShellExecute = false,
            RedirectStandardOutput = true,
            RedirectStandardError = true,
            CreateNoWindow = true
        };

        using var process = new Process { StartInfo = startInfo };

        process.OutputDataReceived += (_, e) =>
        {
            if (e.Data != null)
                Console.WriteLine(e.Data);
        };

        process.ErrorDataReceived += (_, e) =>
        {
            if (e.Data != null)
                Console.Error.WriteLine(e.Data);
        };

        process.Start();
        process.BeginOutputReadLine();
        process.BeginErrorReadLine();

        await process.WaitForExitAsync();
        return process.ExitCode;
    }

    /// <summary>
    /// Finds the project root by searching for the Makefile.
    /// </summary>
    private static string? FindProjectRoot()
    {
        var directory = Directory.GetCurrentDirectory();

        while (directory != null)
        {
            if (File.Exists(Path.Combine(directory, "Makefile")))
            {
                // Verify it's our Makefile by checking for a known target
                var makefileContent = File.ReadAllText(Path.Combine(directory, "Makefile"));
                if (makefileContent.Contains("K8sEscapeRoom"))
                {
                    return directory;
                }
            }

            directory = Directory.GetParent(directory)?.FullName;
        }

        return null;
    }
}
