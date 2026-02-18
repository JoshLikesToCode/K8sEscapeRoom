using K8sEscapeRoom.Api.Services.Storage;
using Xunit;

namespace K8sEscapeRoom.Api.Tests.Services.Storage;

public class TableKeyNormalizerTests
{
    // ========================================================================
    // Basic Normalization
    // ========================================================================

    [Theory]
    [InlineData("simple", "simple")]
    [InlineData("room-test", "room-test")]
    [InlineData("user-123-abc", "user-123-abc")]
    public void NormalizeUserId_NoSpecialChars_ReturnsUnchanged(string input, string expected)
    {
        var result = TableKeyNormalizer.NormalizeUserId(input);
        Assert.Equal(expected, result);
    }

    [Theory]
    [InlineData("simple", "simple")]
    [InlineData("room-groundhog-deploy", "room-groundhog-deploy")]
    [InlineData("boss-checkout-meltdown", "boss-checkout-meltdown")]
    public void NormalizeRoomId_NoSpecialChars_ReturnsUnchanged(string input, string expected)
    {
        var result = TableKeyNormalizer.NormalizeRoomId(input);
        Assert.Equal(expected, result);
    }

    // ========================================================================
    // Special Character Replacement
    // ========================================================================

    [Theory]
    [InlineData("user/name", "user_name")]
    [InlineData("user\\name", "user_name")]
    [InlineData("user#name", "user_name")]
    [InlineData("user?name", "user_name")]
    public void NormalizeUserId_SpecialChars_ReplacesWithUnderscore(string input, string expected)
    {
        var result = TableKeyNormalizer.NormalizeUserId(input);
        Assert.Equal(expected, result);
    }

    [Fact]
    public void NormalizeUserId_MultipleSpecialChars_ReplacesAll()
    {
        var input = "user/with\\special#chars?here";
        var expected = "user_with_special_chars_here";

        var result = TableKeyNormalizer.NormalizeUserId(input);

        Assert.Equal(expected, result);
    }

    // ========================================================================
    // Edge Cases
    // ========================================================================

    [Fact]
    public void NormalizeUserId_Empty_ReturnsEmpty()
    {
        var result = TableKeyNormalizer.NormalizeUserId("");
        Assert.Equal("", result);
    }

    [Fact]
    public void NormalizeRoomId_Empty_ReturnsEmpty()
    {
        var result = TableKeyNormalizer.NormalizeRoomId("");
        Assert.Equal("", result);
    }

    // ========================================================================
    // Consistency Between Methods
    // ========================================================================

    [Theory]
    [InlineData("test/value")]
    [InlineData("test\\value")]
    [InlineData("test#value")]
    [InlineData("test?value")]
    public void NormalizeUserId_And_NormalizeRoomId_ProduceSameOutput(string input)
    {
        var userId = TableKeyNormalizer.NormalizeUserId(input);
        var roomId = TableKeyNormalizer.NormalizeRoomId(input);

        Assert.Equal(userId, roomId);
    }
}
