using System.CommandLine;
using K8sEscapeRoom.Cli.Services;

namespace K8sEscapeRoom.Cli.Commands;

/// <summary>
/// Commands for diagnosing system setup and prerequisites.
/// </summary>
public static class DoctorCommands
{
    /// <summary>
    /// escape doctor → Check all prerequisites and show remediation hints
    /// </summary>
    public static Command Create(DoctorService doctorService)
    {
        var command = new Command("doctor", "Check prerequisites and diagnose issues")
        {
            CreateRunCommand(doctorService)
        };

        // Also allow running doctor directly without subcommand
        command.SetHandler(async () =>
        {
            await RunDoctorAsync(doctorService);
        });

        return command;
    }

    private static Command CreateRunCommand(DoctorService doctorService)
    {
        var command = new Command("run", "Run all diagnostic checks");

        command.SetHandler(async () =>
        {
            await RunDoctorAsync(doctorService);
        });

        return command;
    }

    private static async Task RunDoctorAsync(DoctorService doctorService)
    {
        Console.WriteLine();
        Console.WriteLine("\u001b[36m🔍 K8sEscapeRoom Doctor\u001b[0m");
        Console.WriteLine("\u001b[36m" + new string('─', 40) + "\u001b[0m");
        Console.WriteLine();

        var results = await doctorService.RunAllChecksAsync();
        var allPassed = true;

        foreach (var result in results)
        {
            var icon = result.Passed ? "\u001b[32m✓\u001b[0m" : "\u001b[31m✗\u001b[0m";
            var status = result.Passed ? "\u001b[32mPASS\u001b[0m" : "\u001b[31mFAIL\u001b[0m";
            var version = result.Version != null ? $" ({result.Version})" : "";

            Console.WriteLine($"  {icon} {result.Name,-12} {status}{version}");

            if (!string.IsNullOrEmpty(result.Message) && !result.Passed)
            {
                Console.WriteLine($"    \u001b[90m{result.Message}\u001b[0m");
            }

            if (!result.Passed && !string.IsNullOrEmpty(result.Hint))
            {
                Console.WriteLine($"    \u001b[33m→ {result.Hint}\u001b[0m");
                allPassed = false;
            }

            Console.WriteLine();
        }

        Console.WriteLine("\u001b[36m" + new string('─', 40) + "\u001b[0m");

        if (allPassed)
        {
            Console.WriteLine();
            Console.WriteLine("\u001b[32m✓ All checks passed! You're ready to escape.\u001b[0m");
            Console.WriteLine();
            Console.WriteLine("Next steps:");
            Console.WriteLine("  1. Start a cluster:  \u001b[36mescape cluster up\u001b[0m");
            Console.WriteLine("  2. List rooms:       \u001b[36mescape room list\u001b[0m");
            Console.WriteLine("  3. Start escaping:   \u001b[36mescape quickstart\u001b[0m");
            Console.WriteLine();
            Environment.ExitCode = 0;
        }
        else
        {
            Console.WriteLine();
            Console.WriteLine("\u001b[31m✗ Some checks failed. Fix the issues above and run 'escape doctor' again.\u001b[0m");
            Console.WriteLine();
            Environment.ExitCode = 1;
        }
    }
}
