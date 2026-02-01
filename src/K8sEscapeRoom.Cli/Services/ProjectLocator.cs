namespace K8sEscapeRoom.Cli.Services;

/// <summary>
/// Locates the K8sEscapeRoom project root directory.
/// </summary>
public static class ProjectLocator
{
    private const string MakefileMarker = "K8sEscapeRoom";

    /// <summary>
    /// Finds the project root by searching for the Makefile.
    /// </summary>
    /// <returns>The project root path, or null if not found.</returns>
    public static string? FindProjectRoot()
    {
        return FindProjectRoot(Directory.GetCurrentDirectory());
    }

    /// <summary>
    /// Finds the project root starting from a specific directory.
    /// </summary>
    public static string? FindProjectRoot(string startDirectory)
    {
        var directory = startDirectory;

        while (directory is not null)
        {
            var makefilePath = Path.Combine(directory, "Makefile");

            if (File.Exists(makefilePath))
            {
                // Verify it's our Makefile
                var content = File.ReadAllText(makefilePath);
                if (content.Contains(MakefileMarker))
                {
                    return directory;
                }
            }

            directory = Directory.GetParent(directory)?.FullName;
        }

        return null;
    }

    /// <summary>
    /// Gets the project root or throws if not found.
    /// </summary>
    public static string GetProjectRootOrThrow()
    {
        return FindProjectRoot()
            ?? throw new InvalidOperationException(
                "Could not find K8sEscapeRoom project root. " +
                "Ensure you're running from within the project directory.");
    }
}
