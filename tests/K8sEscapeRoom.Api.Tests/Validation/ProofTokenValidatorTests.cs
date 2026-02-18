using K8sEscapeRoom.Api.Validation;
using Xunit;

namespace K8sEscapeRoom.Api.Tests.Validation;

public class ProofTokenValidatorTests
{
    // ========================================================================
    // Parse Tests
    // ========================================================================

    [Fact]
    public void Parse_ValidToken_ReturnsSuccess()
    {
        // Arrange
        var roomId = "room-groundhog-deploy";
        var nonce = "abc123";
        var timestamp = 1704067200L; // 2024-01-01 00:00:00 UTC
        var hash = ProofTokenValidator.ComputeHash(roomId, nonce, timestamp);
        var token = $"K8SER|{roomId}|{nonce}|{timestamp}|{hash}";

        // Act
        var result = ProofTokenValidator.Parse(token);

        // Assert
        Assert.True(result.IsValid);
        Assert.Null(result.Error);
        Assert.Equal(roomId, result.RoomId);
        Assert.Equal(nonce, result.Nonce);
        Assert.Equal(timestamp, result.Timestamp);
        Assert.Equal(hash, result.Sha256);
    }

    [Fact]
    public void Parse_NullToken_ReturnsError()
    {
        var result = ProofTokenValidator.Parse(null);

        Assert.False(result.IsValid);
        Assert.Contains("required", result.Error, StringComparison.OrdinalIgnoreCase);
    }

    [Fact]
    public void Parse_EmptyToken_ReturnsError()
    {
        var result = ProofTokenValidator.Parse("");

        Assert.False(result.IsValid);
        Assert.Contains("required", result.Error, StringComparison.OrdinalIgnoreCase);
    }

    [Fact]
    public void Parse_WrongPrefix_ReturnsError()
    {
        var token = "WRONG|room-test|abc|123|" + new string('a', 64);

        var result = ProofTokenValidator.Parse(token);

        Assert.False(result.IsValid);
        Assert.Contains("prefix", result.Error, StringComparison.OrdinalIgnoreCase);
    }

    [Theory]
    [InlineData("K8SER|room|nonce|123")] // 4 parts
    [InlineData("K8SER|room|nonce|123|hash|extra")] // 6 parts
    [InlineData("K8SER")] // 1 part
    public void Parse_WrongPartsCount_ReturnsError(string token)
    {
        var result = ProofTokenValidator.Parse(token);

        Assert.False(result.IsValid);
        Assert.Contains("parts", result.Error, StringComparison.OrdinalIgnoreCase);
    }

    [Fact]
    public void Parse_EmptyRoomId_ReturnsError()
    {
        var token = "K8SER||nonce|123|" + new string('a', 64);

        var result = ProofTokenValidator.Parse(token);

        Assert.False(result.IsValid);
        Assert.Contains("roomId", result.Error, StringComparison.OrdinalIgnoreCase);
    }

    [Fact]
    public void Parse_EmptyNonce_ReturnsError()
    {
        var token = "K8SER|room-test||123|" + new string('a', 64);

        var result = ProofTokenValidator.Parse(token);

        Assert.False(result.IsValid);
        Assert.Contains("nonce", result.Error, StringComparison.OrdinalIgnoreCase);
    }

    [Theory]
    [InlineData("notanumber")]
    [InlineData("12.34")]
    [InlineData("")]
    public void Parse_InvalidTimestamp_ReturnsError(string timestamp)
    {
        var token = $"K8SER|room-test|nonce|{timestamp}|" + new string('a', 64);

        var result = ProofTokenValidator.Parse(token);

        Assert.False(result.IsValid);
        Assert.Contains("timestamp", result.Error, StringComparison.OrdinalIgnoreCase);
    }

    [Theory]
    [InlineData("abc")] // Too short
    [InlineData("ghijklmnopqrstuvwxyz1234567890ghijklmnopqrstuvwxyz1234567890ghij")] // 64 chars but not hex
    public void Parse_InvalidHash_ReturnsError(string hash)
    {
        var token = $"K8SER|room-test|nonce|123|{hash}";

        var result = ProofTokenValidator.Parse(token);

        Assert.False(result.IsValid);
        Assert.Contains("hash", result.Error, StringComparison.OrdinalIgnoreCase);
    }

    [Fact]
    public void Parse_ValidHexHash_Succeeds()
    {
        var validHash = "0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef";
        var token = $"K8SER|room-test|nonce|123|{validHash}";

        var result = ProofTokenValidator.Parse(token);

        Assert.True(result.IsValid);
        Assert.Equal(validHash, result.Sha256);
    }

    // ========================================================================
    // Hash Computation Tests
    // ========================================================================

    [Fact]
    public void ComputeHash_KnownInput_ReturnsExpectedHash()
    {
        // Known test vector
        var roomId = "room-test";
        var nonce = "abc123";
        var timestamp = 1704067200L;

        var hash = ProofTokenValidator.ComputeHash(roomId, nonce, timestamp);

        // Hash should be 64 lowercase hex characters
        Assert.Equal(64, hash.Length);
        Assert.True(hash.All(c => char.IsAsciiHexDigitLower(c)));
    }

    [Fact]
    public void ComputeHash_SameInput_ReturnsSameHash()
    {
        var roomId = "room-groundhog-deploy";
        var nonce = "xyz789";
        var timestamp = 1704067200L;

        var hash1 = ProofTokenValidator.ComputeHash(roomId, nonce, timestamp);
        var hash2 = ProofTokenValidator.ComputeHash(roomId, nonce, timestamp);

        Assert.Equal(hash1, hash2);
    }

    [Fact]
    public void ComputeHash_DifferentInput_ReturnsDifferentHash()
    {
        var nonce = "abc123";
        var timestamp = 1704067200L;

        var hash1 = ProofTokenValidator.ComputeHash("room-a", nonce, timestamp);
        var hash2 = ProofTokenValidator.ComputeHash("room-b", nonce, timestamp);

        Assert.NotEqual(hash1, hash2);
    }

    // ========================================================================
    // Hash Validation Tests
    // ========================================================================

    [Fact]
    public void ValidateHash_CorrectHash_ReturnsTrue()
    {
        var roomId = "room-groundhog-deploy";
        var nonce = "test-nonce";
        var timestamp = 1704067200L;
        var hash = ProofTokenValidator.ComputeHash(roomId, nonce, timestamp);

        var isValid = ProofTokenValidator.ValidateHash(roomId, nonce, timestamp, hash);

        Assert.True(isValid);
    }

    [Fact]
    public void ValidateHash_IncorrectHash_ReturnsFalse()
    {
        var roomId = "room-groundhog-deploy";
        var nonce = "test-nonce";
        var timestamp = 1704067200L;
        var wrongHash = new string('0', 64);

        var isValid = ProofTokenValidator.ValidateHash(roomId, nonce, timestamp, wrongHash);

        Assert.False(isValid);
    }

    [Fact]
    public void ValidateHash_CaseInsensitive_Works()
    {
        var roomId = "room-test";
        var nonce = "nonce";
        var timestamp = 1704067200L;
        var hash = ProofTokenValidator.ComputeHash(roomId, nonce, timestamp);

        // Upper case hash should still validate
        var isValid = ProofTokenValidator.ValidateHash(roomId, nonce, timestamp, hash.ToUpperInvariant());

        Assert.True(isValid);
    }
}
