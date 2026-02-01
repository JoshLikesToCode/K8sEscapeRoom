using K8sEscapeRoom.Cli.Services;
using Xunit;

namespace K8sEscapeRoom.Cli.Tests;

/// <summary>
/// Tests for RoomService functionality.
/// </summary>
public class RoomServiceTests
{
    [Fact]
    public void ExtractSummary_ReturnsNull_WhenContentIsNull()
    {
        // Act
        var result = RoomService.ExtractSummary(null);

        // Assert
        Assert.Null(result);
    }

    [Fact]
    public void ExtractSummary_ReturnsNull_WhenContentIsEmpty()
    {
        // Act
        var result = RoomService.ExtractSummary("");

        // Assert
        Assert.Null(result);
    }

    [Fact]
    public void ExtractSummary_SkipsHeaders()
    {
        // Arrange
        var content = """
            # Title
            ## Subtitle

            This is the first content line.
            This is the second line.
            """;

        // Act
        var result = RoomService.ExtractSummary(content);

        // Assert
        Assert.Equal("This is the first content line.", result);
    }

    [Fact]
    public void ExtractSummary_ReturnsFirstNonEmptyLine()
    {
        // Arrange
        var content = """
            # Title


            The actual content.
            """;

        // Act
        var result = RoomService.ExtractSummary(content);

        // Assert
        Assert.Equal("The actual content.", result);
    }

    [Fact]
    public void ExtractHintLevel_ReturnsNull_WhenLevelNotFound()
    {
        // Arrange
        var content = """
            # Hints

            ## Hint Level 1: First
            Some hint content.

            ## Hint Level 2: Second
            More hint content.
            """;

        // Act
        var result = RoomService.ExtractHintLevel(content, 5);

        // Assert
        Assert.Null(result);
    }

    [Fact]
    public void ExtractHintLevel_ReturnsCorrectSection()
    {
        // Arrange
        var content = """
            # Hints

            ## Hint Level 1: First
            First hint content.
            With multiple lines.

            ## Hint Level 2: Second
            Second hint content.

            ## Hint Level 3: Third
            Third hint content.
            """;

        // Act
        var result = RoomService.ExtractHintLevel(content, 2);

        // Assert
        Assert.NotNull(result);
        Assert.Contains("## Hint Level 2: Second", result);
        Assert.Contains("Second hint content.", result);
        Assert.DoesNotContain("First hint", result);
        Assert.DoesNotContain("Third hint", result);
    }

    [Fact]
    public void ExtractHintLevel_HandlesLastSection()
    {
        // Arrange
        var content = """
            ## Hint Level 1: First
            First hint.

            ## Hint Level 4: Last
            Last hint content.
            Final line.
            """;

        // Act
        var result = RoomService.ExtractHintLevel(content, 4);

        // Assert
        Assert.NotNull(result);
        Assert.Contains("## Hint Level 4: Last", result);
        Assert.Contains("Last hint content.", result);
        Assert.Contains("Final line.", result);
    }
}
