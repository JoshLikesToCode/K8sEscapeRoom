using Azure;
using Azure.Data.Tables;
using K8sEscapeRoom.Api.Models;

namespace K8sEscapeRoom.Api.Services.Storage;

/// <summary>
/// Azure Table Storage implementation for room progress.
/// Uses PartitionKey = UserId, RowKey = RoomId for efficient queries.
/// </summary>
public class TableProgressStorage : IProgressStorage
{
    private readonly TableClient _tableClient;
    private const string DefaultTableName = "K8sEscapeRoomProgress";

    public TableProgressStorage(string connectionString, string? tableName = null)
    {
        var serviceClient = new TableServiceClient(connectionString);
        _tableClient = serviceClient.GetTableClient(tableName ?? DefaultTableName);
        _tableClient.CreateIfNotExists();
    }

    public async Task<IReadOnlyList<string>> GetCompletedRoomsAsync(string userId)
    {
        var rooms = new List<string>();

        // Query all rows with this userId as partition key
        await foreach (var entity in _tableClient.QueryAsync<RoomProgressEntity>(
            filter: $"PartitionKey eq '{EscapeTableKey(userId)}'"))
        {
            rooms.Add(entity.RoomId);
        }

        return rooms;
    }

    public async Task MarkRoomCompleteAsync(string userId, string roomId)
    {
        var entity = new RoomProgressEntity(userId, roomId);

        // Upsert: insert or update (idempotent)
        await _tableClient.UpsertEntityAsync(entity, TableUpdateMode.Replace);
    }

    public async Task<bool> IsRoomCompletedAsync(string userId, string roomId)
    {
        try
        {
            var response = await _tableClient.GetEntityAsync<RoomProgressEntity>(
                EscapeTableKey(userId),
                EscapeTableKey(roomId)
            );
            return response.Value != null;
        }
        catch (RequestFailedException ex) when (ex.Status == 404)
        {
            return false;
        }
    }

    /// <summary>
    /// Escape special characters in table keys
    /// </summary>
    private static string EscapeTableKey(string key)
    {
        // Table Storage disallows: / \ # ?
        return key
            .Replace("/", "_")
            .Replace("\\", "_")
            .Replace("#", "_")
            .Replace("?", "_");
    }
}
