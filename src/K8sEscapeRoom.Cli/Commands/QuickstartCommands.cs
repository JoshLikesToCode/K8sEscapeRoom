using System.CommandLine;
using K8sEscapeRoom.Cli.Services;

namespace K8sEscapeRoom.Cli.Commands;

/// <summary>
/// Commands for quick onboarding and tutorial.
/// </summary>
public static class QuickstartCommands
{
    private const string TutorialRoom = "room-crashloop-env";

    /// <summary>
    /// escape quickstart → Run the quickstart tutorial
    /// </summary>
    public static Command Create(
        DoctorService doctorService,
        ClusterService clusterService,
        RoomService roomService)
    {
        var command = new Command("quickstart", "Start a guided tutorial to learn K8sEscapeRoom");

        var skipDoctorOption = new Option<bool>(
            aliases: ["--skip-doctor", "-s"],
            description: "Skip prerequisite checks");

        command.AddOption(skipDoctorOption);

        command.SetHandler(async (bool skipDoctor) =>
        {
            await RunQuickstartAsync(doctorService, clusterService, roomService, skipDoctor);
        }, skipDoctorOption);

        return command;
    }

    private static async Task RunQuickstartAsync(
        DoctorService doctorService,
        ClusterService clusterService,
        RoomService roomService,
        bool skipDoctor)
    {
        PrintBanner();

        // Step 1: Run doctor checks
        if (!skipDoctor)
        {
            Console.WriteLine("\u001b[36m📋 Step 1: Checking prerequisites...\u001b[0m");
            Console.WriteLine();

            var results = await doctorService.RunAllChecksAsync();
            var criticalFailed = results
                .Where(r => r.Name is "Docker" or "kubectl" or "kind" or "make")
                .Any(r => !r.Passed);

            foreach (var result in results)
            {
                var icon = result.Passed ? "\u001b[32m✓\u001b[0m" : "\u001b[31m✗\u001b[0m";
                Console.WriteLine($"  {icon} {result.Name}");

                if (!result.Passed && !string.IsNullOrEmpty(result.Hint))
                {
                    Console.WriteLine($"    \u001b[33m→ {result.Hint}\u001b[0m");
                }
            }

            Console.WriteLine();

            if (criticalFailed)
            {
                Console.WriteLine("\u001b[31m✗ Prerequisites not met. Fix the issues above first.\u001b[0m");
                Console.WriteLine("  Run \u001b[36mescape doctor\u001b[0m for detailed diagnostics.");
                Console.WriteLine();
                Environment.ExitCode = 1;
                return;
            }

            Console.WriteLine("\u001b[32m✓ Prerequisites OK!\u001b[0m");
            Console.WriteLine();
        }

        // Step 2: Ensure cluster is running
        Console.WriteLine("\u001b[36m🚀 Step 2: Checking cluster...\u001b[0m");
        Console.WriteLine();

        var clusterStatus = await clusterService.StatusAsync();
        if (clusterStatus.ExitCode != 0)
        {
            Console.WriteLine("  Cluster not found. Creating one...");
            Console.WriteLine();

            var upResult = await clusterService.UpAsync();
            if (upResult.ExitCode != 0)
            {
                Console.WriteLine();
                Console.WriteLine("\u001b[31m✗ Failed to create cluster.\u001b[0m");
                Console.WriteLine("  Try manually: \u001b[36mescape cluster up\u001b[0m");
                Environment.ExitCode = 1;
                return;
            }
        }

        Console.WriteLine("\u001b[32m✓ Cluster ready!\u001b[0m");
        Console.WriteLine();

        // Step 3: Show tutorial intro
        Console.WriteLine("\u001b[36m📚 Step 3: Your First Escape Room\u001b[0m");
        Console.WriteLine();
        Console.WriteLine("  You'll be working with: \u001b[33m" + TutorialRoom + "\u001b[0m");
        Console.WriteLine();

        // Show objective
        var objective = roomService.GetObjective(TutorialRoom);
        if (objective != null)
        {
            var summary = RoomService.ExtractSummary(objective);
            if (summary != null)
            {
                Console.WriteLine($"  \u001b[90m{summary}\u001b[0m");
                Console.WriteLine();
            }
        }

        // Step 4: Apply the room
        Console.WriteLine("\u001b[36m🔧 Step 4: Applying the broken room...\u001b[0m");
        Console.WriteLine();

        var applyResult = await roomService.ApplyRoomAsync(TutorialRoom);
        if (applyResult.ExitCode != 0)
        {
            Console.WriteLine();
            Console.WriteLine("\u001b[31m✗ Failed to apply room.\u001b[0m");
            Environment.ExitCode = 1;
            return;
        }

        Console.WriteLine();
        Console.WriteLine("\u001b[32m✓ Room applied!\u001b[0m");
        Console.WriteLine();

        // Step 5: Show next steps
        PrintNextSteps();
    }

    private static void PrintBanner()
    {
        Console.WriteLine();
        Console.WriteLine("\u001b[36m╔══════════════════════════════════════════════════════════╗\u001b[0m");
        Console.WriteLine("\u001b[36m║                                                          ║\u001b[0m");
        Console.WriteLine("\u001b[36m║   \u001b[33m🔐 K8sEscapeRoom Quickstart\u001b[36m                            ║\u001b[0m");
        Console.WriteLine("\u001b[36m║                                                          ║\u001b[0m");
        Console.WriteLine("\u001b[36m║   Debug Kubernetes failures. Escape each room.          ║\u001b[0m");
        Console.WriteLine("\u001b[36m║                                                          ║\u001b[0m");
        Console.WriteLine("\u001b[36m╚══════════════════════════════════════════════════════════╝\u001b[0m");
        Console.WriteLine();
    }

    private static void PrintNextSteps()
    {
        Console.WriteLine("\u001b[36m" + new string('═', 60) + "\u001b[0m");
        Console.WriteLine();
        Console.WriteLine("\u001b[32m🎮 Your escape room is ready!\u001b[0m");
        Console.WriteLine();
        Console.WriteLine("The room is now in a broken state. Your mission:");
        Console.WriteLine();
        Console.WriteLine("  1. \u001b[33mInvestigate\u001b[0m - Find out what's wrong:");
        Console.WriteLine($"     \u001b[36mkubectl get pods -n escape-{TutorialRoom}\u001b[0m");
        Console.WriteLine($"     \u001b[36mkubectl describe pod -n escape-{TutorialRoom}\u001b[0m");
        Console.WriteLine();
        Console.WriteLine("  2. \u001b[33mRead the objective\u001b[0m:");
        Console.WriteLine($"     \u001b[36mescape room objective {TutorialRoom}\u001b[0m");
        Console.WriteLine();
        Console.WriteLine("  3. \u001b[33mNeed hints?\u001b[0m:");
        Console.WriteLine($"     \u001b[36mescape room hint {TutorialRoom} --level 1\u001b[0m");
        Console.WriteLine();
        Console.WriteLine("  4. \u001b[33mFix the issue\u001b[0m using kubectl commands");
        Console.WriteLine();
        Console.WriteLine("  5. \u001b[33mVerify your fix\u001b[0m:");
        Console.WriteLine($"     \u001b[36mescape room verify {TutorialRoom}\u001b[0m");
        Console.WriteLine();
        Console.WriteLine("\u001b[90mStuck? Run: escape room solution " + TutorialRoom + "\u001b[0m");
        Console.WriteLine();
        Console.WriteLine("\u001b[36m" + new string('═', 60) + "\u001b[0m");
        Console.WriteLine();
        Console.WriteLine("📖 Full docs: https://k8sescaperoom.dev/getting-started");
        Console.WriteLine();
    }
}
