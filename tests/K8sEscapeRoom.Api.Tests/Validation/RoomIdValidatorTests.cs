using K8sEscapeRoom.Api.Validation;
using Xunit;

namespace K8sEscapeRoom.Api.Tests.Validation;

public class RoomIdValidatorTests
{
    // ========================================================================
    // Valid Room IDs
    // ========================================================================

    [Theory]
    [InlineData("room-crashloop-env")]
    [InlineData("room-imagepullbackoff")]
    [InlineData("room-pending-resources")]
    [InlineData("room-probe-doom")]
    [InlineData("room-a")]
    [InlineData("room-123")]
    [InlineData("room-test-123-abc")]
    public void IsValid_ValidRoomId_ReturnsTrue(string roomId)
    {
        Assert.True(RoomIdValidator.IsValid(roomId));
    }

    [Theory]
    [InlineData("boss-checkout-meltdown")]
    [InlineData("boss-security-lockdown")]
    [InlineData("boss-a")]
    [InlineData("boss-123")]
    public void IsValid_ValidBossId_ReturnsTrue(string roomId)
    {
        Assert.True(RoomIdValidator.IsValid(roomId));
    }

    // ========================================================================
    // Invalid Room IDs - Null/Empty
    // ========================================================================

    [Fact]
    public void IsValid_Null_ReturnsFalse()
    {
        Assert.False(RoomIdValidator.IsValid(null));
    }

    [Fact]
    public void IsValid_Empty_ReturnsFalse()
    {
        Assert.False(RoomIdValidator.IsValid(""));
    }

    [Fact]
    public void IsValid_Whitespace_ReturnsFalse()
    {
        Assert.False(RoomIdValidator.IsValid("   "));
    }

    // ========================================================================
    // Invalid Room IDs - Wrong Prefix
    // ========================================================================

    [Theory]
    [InlineData("test-crashloop")]
    [InlineData("level-1")]
    [InlineData("crashloop-env")]
    [InlineData("roomcrashloop")]
    [InlineData("bosscrashloop")]
    public void IsValid_WrongPrefix_ReturnsFalse(string roomId)
    {
        Assert.False(RoomIdValidator.IsValid(roomId));
    }

    // ========================================================================
    // Invalid Room IDs - Path Separators (Security)
    // ========================================================================

    [Theory]
    [InlineData("room-../etc/passwd")]
    [InlineData("room-test/subdir")]
    [InlineData("room-test\\subdir")]
    [InlineData("boss-../attack")]
    public void IsValid_PathSeparators_ReturnsFalse(string roomId)
    {
        Assert.False(RoomIdValidator.IsValid(roomId));
    }

    // ========================================================================
    // Invalid Room IDs - Special Characters
    // ========================================================================

    [Theory]
    [InlineData("room-test#1")]
    [InlineData("room-test?query")]
    [InlineData("room-test@domain")]
    [InlineData("room-test!bang")]
    [InlineData("room-test space")]
    [InlineData("room-TEST")]  // Uppercase not allowed
    [InlineData("room-Test")]  // Mixed case not allowed
    public void IsValid_SpecialCharacters_ReturnsFalse(string roomId)
    {
        Assert.False(RoomIdValidator.IsValid(roomId));
    }

    // ========================================================================
    // Invalid Room IDs - Just Prefix
    // ========================================================================

    [Theory]
    [InlineData("room-")]
    [InlineData("boss-")]
    public void IsValid_JustPrefix_ReturnsFalse(string roomId)
    {
        Assert.False(RoomIdValidator.IsValid(roomId));
    }

    // ========================================================================
    // Error Messages
    // ========================================================================

    [Fact]
    public void GetErrorMessage_Null_ReturnsRequiredMessage()
    {
        var message = RoomIdValidator.GetErrorMessage(null);
        Assert.Contains("required", message, StringComparison.OrdinalIgnoreCase);
    }

    [Fact]
    public void GetErrorMessage_PathSeparator_ReturnsPathMessage()
    {
        var message = RoomIdValidator.GetErrorMessage("room-../test");
        Assert.Contains("path", message, StringComparison.OrdinalIgnoreCase);
    }

    [Fact]
    public void GetErrorMessage_WrongPrefix_ReturnsPrefixMessage()
    {
        var message = RoomIdValidator.GetErrorMessage("test-room");
        Assert.Contains("room-", message, StringComparison.OrdinalIgnoreCase);
        Assert.Contains("boss-", message, StringComparison.OrdinalIgnoreCase);
    }

    [Fact]
    public void GetErrorMessage_InvalidChars_ReturnsCharacterMessage()
    {
        var message = RoomIdValidator.GetErrorMessage("room-TEST");
        Assert.Contains("lowercase", message, StringComparison.OrdinalIgnoreCase);
    }
}
