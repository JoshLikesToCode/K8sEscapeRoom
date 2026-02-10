using K8sEscapeRoom.Api.Models;
using Xunit;

namespace K8sEscapeRoom.Api.Tests.Models;

public class AttemptEntityTests
{
    // ========================================================================
    // Expiry Tests
    // ========================================================================

    [Fact]
    public void IsExpired_BeforeExpiry_ReturnsFalse()
    {
        var attempt = new AttemptEntity
        {
            ExpiresAtUtc = DateTimeOffset.UtcNow.AddMinutes(30)
        };

        Assert.False(attempt.IsExpired);
    }

    [Fact]
    public void IsExpired_AfterExpiry_ReturnsTrue()
    {
        var attempt = new AttemptEntity
        {
            ExpiresAtUtc = DateTimeOffset.UtcNow.AddMinutes(-1)
        };

        Assert.True(attempt.IsExpired);
    }

    // ========================================================================
    // CanBeUsed Tests
    // ========================================================================

    [Fact]
    public void CanBeUsed_NotUsedNotExpired_ReturnsTrue()
    {
        var attempt = new AttemptEntity
        {
            IsUsed = false,
            ExpiresAtUtc = DateTimeOffset.UtcNow.AddMinutes(30)
        };

        Assert.True(attempt.CanBeUsed);
    }

    [Fact]
    public void CanBeUsed_AlreadyUsed_ReturnsFalse()
    {
        var attempt = new AttemptEntity
        {
            IsUsed = true,
            ExpiresAtUtc = DateTimeOffset.UtcNow.AddMinutes(30)
        };

        Assert.False(attempt.CanBeUsed);
    }

    [Fact]
    public void CanBeUsed_Expired_ReturnsFalse()
    {
        var attempt = new AttemptEntity
        {
            IsUsed = false,
            ExpiresAtUtc = DateTimeOffset.UtcNow.AddMinutes(-1)
        };

        Assert.False(attempt.CanBeUsed);
    }

    [Fact]
    public void CanBeUsed_UsedAndExpired_ReturnsFalse()
    {
        var attempt = new AttemptEntity
        {
            IsUsed = true,
            ExpiresAtUtc = DateTimeOffset.UtcNow.AddMinutes(-1)
        };

        Assert.False(attempt.CanBeUsed);
    }

    // ========================================================================
    // Convenience Properties Tests
    // ========================================================================

    [Fact]
    public void UserId_ReturnsPartitionKey()
    {
        var attempt = new AttemptEntity
        {
            PartitionKey = "user-123"
        };

        Assert.Equal("user-123", attempt.UserId);
    }

    [Fact]
    public void RoomId_ReturnsOriginalRoomIdIfSet()
    {
        var attempt = new AttemptEntity
        {
            RowKey = "room_normalized",
            OriginalRoomId = "room-original"
        };

        Assert.Equal("room-original", attempt.RoomId);
    }

    [Fact]
    public void RoomId_ReturnsRowKeyIfOriginalNotSet()
    {
        var attempt = new AttemptEntity
        {
            RowKey = "room-test",
            OriginalRoomId = null
        };

        Assert.Equal("room-test", attempt.RoomId);
    }
}
