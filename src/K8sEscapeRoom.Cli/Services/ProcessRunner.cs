using System.Diagnostics;

namespace K8sEscapeRoom.Cli.Services;

/// <summary>
/// Executes external processes with streaming output, proper exit codes, and cancellation support.
/// </summary>
public sealed class ProcessRunner : IDisposable
{
    private readonly CancellationTokenSource _globalCts = new();
    private Process? _currentProcess;
    private readonly object _processLock = new();

    public ProcessRunner()
    {
        // Handle Ctrl+C gracefully
        Console.CancelKeyPress += OnCancelKeyPress;
    }

    /// <summary>
    /// Result of a process execution.
    /// </summary>
    public record ProcessResult(int ExitCode, bool WasCancelled);

    /// <summary>
    /// Runs a command with arguments, streaming output to console.
    /// </summary>
    public async Task<ProcessResult> RunAsync(
        string command,
        string arguments,
        string workingDirectory,
        CancellationToken cancellationToken = default)
    {
        using var linkedCts = CancellationTokenSource.CreateLinkedTokenSource(
            cancellationToken, _globalCts.Token);
        var token = linkedCts.Token;

        var startInfo = new ProcessStartInfo
        {
            FileName = command,
            Arguments = arguments,
            WorkingDirectory = workingDirectory,
            UseShellExecute = false,
            RedirectStandardOutput = true,
            RedirectStandardError = true,
            CreateNoWindow = true,
            // Ensure proper signal handling
            Environment = { ["TERM"] = "xterm-256color" }
        };

        using var process = new Process { StartInfo = startInfo };

        // Track current process for cancellation
        lock (_processLock)
        {
            _currentProcess = process;
        }

        try
        {
            // Set up output handlers
            var outputTcs = new TaskCompletionSource<bool>();
            var errorTcs = new TaskCompletionSource<bool>();

            process.OutputDataReceived += (_, e) =>
            {
                if (e.Data is not null)
                    Console.WriteLine(e.Data);
                else
                    outputTcs.TrySetResult(true);
            };

            process.ErrorDataReceived += (_, e) =>
            {
                if (e.Data is not null)
                    Console.Error.WriteLine(e.Data);
                else
                    errorTcs.TrySetResult(true);
            };

            process.Start();
            process.BeginOutputReadLine();
            process.BeginErrorReadLine();

            // Wait for process with cancellation support
            try
            {
                await process.WaitForExitAsync(token);

                // Wait for output streams to finish (with timeout)
                var outputTask = outputTcs.Task;
                var errorTask = errorTcs.Task;
                await Task.WhenAll(
                    Task.WhenAny(outputTask, Task.Delay(1000, CancellationToken.None)),
                    Task.WhenAny(errorTask, Task.Delay(1000, CancellationToken.None))
                );

                return new ProcessResult(process.ExitCode, WasCancelled: false);
            }
            catch (OperationCanceledException)
            {
                // Kill the process tree on cancellation
                KillProcessTree(process);
                return new ProcessResult(130, WasCancelled: true); // 130 = terminated by Ctrl+C
            }
        }
        finally
        {
            lock (_processLock)
            {
                _currentProcess = null;
            }
        }
    }

    /// <summary>
    /// Runs a make target with optional variables.
    /// </summary>
    public Task<ProcessResult> RunMakeAsync(
        string target,
        string workingDirectory,
        Dictionary<string, string>? variables = null,
        CancellationToken cancellationToken = default)
    {
        var args = target;
        if (variables is not null)
        {
            foreach (var (key, value) in variables)
            {
                args += $" {key}={value}";
            }
        }

        return RunAsync("make", args, workingDirectory, cancellationToken);
    }

    private void OnCancelKeyPress(object? sender, ConsoleCancelEventArgs e)
    {
        e.Cancel = true; // Prevent immediate termination

        Console.Error.WriteLine();
        Console.Error.WriteLine("\u001b[33mCancelling...\u001b[0m");

        // Signal cancellation
        _globalCts.Cancel();

        // Kill current process if running
        lock (_processLock)
        {
            if (_currentProcess is { HasExited: false } process)
            {
                KillProcessTree(process);
            }
        }
    }

    private static void KillProcessTree(Process process)
    {
        try
        {
            // Kill the entire process tree
            process.Kill(entireProcessTree: true);
        }
        catch (InvalidOperationException)
        {
            // Process already exited
        }
        catch (Exception ex)
        {
            Console.Error.WriteLine($"Warning: Could not kill process: {ex.Message}");
        }
    }

    public void Dispose()
    {
        Console.CancelKeyPress -= OnCancelKeyPress;
        _globalCts.Dispose();
    }
}
