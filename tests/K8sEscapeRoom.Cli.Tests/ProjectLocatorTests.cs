using K8sEscapeRoom.Cli.Services;
using Xunit;

namespace K8sEscapeRoom.Cli.Tests;

/// <summary>
/// Tests for ProjectLocator functionality.
/// </summary>
public class ProjectLocatorTests : IDisposable
{
    private readonly string _testDirectory;

    public ProjectLocatorTests()
    {
        _testDirectory = Path.Combine(Path.GetTempPath(), $"K8sEscapeRoom.Tests.{Guid.NewGuid()}");
        Directory.CreateDirectory(_testDirectory);
    }

    public void Dispose()
    {
        if (Directory.Exists(_testDirectory))
        {
            Directory.Delete(_testDirectory, recursive: true);
        }
    }

    [Fact]
    public void FindProjectRoot_ReturnsNull_WhenMakefileNotFound()
    {
        // Arrange
        var emptyDir = Path.Combine(_testDirectory, "empty");
        Directory.CreateDirectory(emptyDir);

        // Act
        var result = ProjectLocator.FindProjectRoot(emptyDir);

        // Assert
        Assert.Null(result);
    }

    [Fact]
    public void FindProjectRoot_ReturnsNull_WhenMakefileDoesNotContainMarker()
    {
        // Arrange
        var dir = Path.Combine(_testDirectory, "wrongproject");
        Directory.CreateDirectory(dir);
        File.WriteAllText(Path.Combine(dir, "Makefile"), "# Some other project\nbuild:\n\techo hello");

        // Act
        var result = ProjectLocator.FindProjectRoot(dir);

        // Assert
        Assert.Null(result);
    }

    [Fact]
    public void FindProjectRoot_FindsMakefileInCurrentDirectory()
    {
        // Arrange
        var dir = Path.Combine(_testDirectory, "project");
        Directory.CreateDirectory(dir);
        File.WriteAllText(Path.Combine(dir, "Makefile"), "# K8sEscapeRoom Makefile\nhelp:\n\techo help");

        // Act
        var result = ProjectLocator.FindProjectRoot(dir);

        // Assert
        Assert.Equal(dir, result);
    }

    [Fact]
    public void FindProjectRoot_FindsMakefileInParentDirectory()
    {
        // Arrange
        var rootDir = Path.Combine(_testDirectory, "project");
        var subDir = Path.Combine(rootDir, "src", "cli");
        Directory.CreateDirectory(subDir);
        File.WriteAllText(Path.Combine(rootDir, "Makefile"), "# K8sEscapeRoom Makefile\nhelp:\n\techo help");

        // Act
        var result = ProjectLocator.FindProjectRoot(subDir);

        // Assert
        Assert.Equal(rootDir, result);
    }

    [Fact]
    public void FindProjectRoot_StopsAtFirstMatchingMakefile()
    {
        // Arrange
        var outerDir = Path.Combine(_testDirectory, "outer");
        var innerDir = Path.Combine(outerDir, "inner");
        Directory.CreateDirectory(innerDir);

        // Both have K8sEscapeRoom marker, but inner should be found first
        File.WriteAllText(Path.Combine(outerDir, "Makefile"), "# K8sEscapeRoom outer");
        File.WriteAllText(Path.Combine(innerDir, "Makefile"), "# K8sEscapeRoom inner");

        // Act
        var result = ProjectLocator.FindProjectRoot(innerDir);

        // Assert
        Assert.Equal(innerDir, result);
    }
}
