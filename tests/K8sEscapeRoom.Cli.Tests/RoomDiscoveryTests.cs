using K8sEscapeRoom.Cli.Services;
using Xunit;

namespace K8sEscapeRoom.Cli.Tests;

/// <summary>
/// Tests for room discovery functionality.
/// </summary>
public class RoomDiscoveryTests : IDisposable
{
    private readonly string _testDirectory;

    public RoomDiscoveryTests()
    {
        // Create a temporary directory for tests
        _testDirectory = Path.Combine(Path.GetTempPath(), $"K8sEscapeRoom.Tests.{Guid.NewGuid()}");
        Directory.CreateDirectory(_testDirectory);
    }

    public void Dispose()
    {
        // Clean up test directory
        if (Directory.Exists(_testDirectory))
        {
            Directory.Delete(_testDirectory, recursive: true);
        }
    }

    [Fact]
    public void DiscoverRooms_ReturnsEmptyList_WhenDirectoryDoesNotExist()
    {
        // Arrange
        var nonExistentPath = Path.Combine(_testDirectory, "nonexistent");

        // Act
        var rooms = RoomService.DiscoverRooms(nonExistentPath);

        // Assert
        Assert.Empty(rooms);
    }

    [Fact]
    public void DiscoverRooms_ReturnsEmptyList_WhenNoRoomDirectoriesExist()
    {
        // Arrange
        var roomsDir = Path.Combine(_testDirectory, "rooms");
        Directory.CreateDirectory(roomsDir);
        Directory.CreateDirectory(Path.Combine(roomsDir, "not-a-room"));
        Directory.CreateDirectory(Path.Combine(roomsDir, "another-folder"));

        // Act
        var rooms = RoomService.DiscoverRooms(roomsDir);

        // Assert
        Assert.Empty(rooms);
    }

    [Fact]
    public void DiscoverRooms_FindsDirectoriesStartingWithRoom()
    {
        // Arrange
        var roomsDir = Path.Combine(_testDirectory, "rooms");
        Directory.CreateDirectory(roomsDir);
        Directory.CreateDirectory(Path.Combine(roomsDir, "room-crashloop-env"));
        Directory.CreateDirectory(Path.Combine(roomsDir, "room-imagepullbackoff"));
        Directory.CreateDirectory(Path.Combine(roomsDir, "room-pending-resources"));
        Directory.CreateDirectory(Path.Combine(roomsDir, "not-a-room")); // Should be excluded

        // Act
        var rooms = RoomService.DiscoverRooms(roomsDir);

        // Assert
        Assert.Equal(3, rooms.Count);
        Assert.Contains("room-crashloop-env", rooms);
        Assert.Contains("room-imagepullbackoff", rooms);
        Assert.Contains("room-pending-resources", rooms);
        Assert.DoesNotContain("not-a-room", rooms);
    }

    [Fact]
    public void DiscoverRooms_ReturnsSortedList()
    {
        // Arrange
        var roomsDir = Path.Combine(_testDirectory, "rooms");
        Directory.CreateDirectory(roomsDir);
        Directory.CreateDirectory(Path.Combine(roomsDir, "room-zebra"));
        Directory.CreateDirectory(Path.Combine(roomsDir, "room-alpha"));
        Directory.CreateDirectory(Path.Combine(roomsDir, "room-middle"));

        // Act
        var rooms = RoomService.DiscoverRooms(roomsDir);

        // Assert
        Assert.Equal(3, rooms.Count);
        Assert.Equal("room-alpha", rooms[0]);
        Assert.Equal("room-middle", rooms[1]);
        Assert.Equal("room-zebra", rooms[2]);
    }

    [Fact]
    public void DiscoverRooms_IgnoresFiles()
    {
        // Arrange
        var roomsDir = Path.Combine(_testDirectory, "rooms");
        Directory.CreateDirectory(roomsDir);
        Directory.CreateDirectory(Path.Combine(roomsDir, "room-valid"));
        File.WriteAllText(Path.Combine(roomsDir, "room-file.txt"), "not a directory");

        // Act
        var rooms = RoomService.DiscoverRooms(roomsDir);

        // Assert
        Assert.Single(rooms);
        Assert.Equal("room-valid", rooms[0]);
    }

    [Fact]
    public void DiscoverRooms_HandlesEmptyRoomsDirectory()
    {
        // Arrange
        var roomsDir = Path.Combine(_testDirectory, "rooms");
        Directory.CreateDirectory(roomsDir);

        // Act
        var rooms = RoomService.DiscoverRooms(roomsDir);

        // Assert
        Assert.Empty(rooms);
    }
}
