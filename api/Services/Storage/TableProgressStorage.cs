using Azure;
using Azure.Data.Tables;
using K8sEscapeRoom.Api.Models;

namespace K8sEscapeRoom.Api.Services.Storage;

/// <summary>
/// Azure Table Storage implementation for room progress.
/// Uses PartitionKey = UserId, RowKey = RoomId for efficient queries.
/// All keys are normalized consistently using TableKeyNormalizer.
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
        var normalizedUserId = TableKeyNormalizer.NormalizeUserId(userId);
        var rooms = new List<string>();

        // Query all rows with this userId as partition key
        await foreach (var entity in _tableClient.QueryAsync<RoomProgressEntity>(
            filter: $"PartitionKey eq '{normalizedUserId}'"))
        {
            // Return the original room ID stored in the entity
            rooms.Add(entity.OriginalRoomId ?? entity.RowKey);
        }

        return rooms;
    }

    public async Task MarkRoomCompleteAsync(string userId, string roomId)
    {
        var normalizedUserId = TableKeyNormalizer.NormalizeUserId(userId);
        var normalizedRoomId = TableKeyNormalizer.NormalizeRoomId(roomId);

        var entity = new RoomProgressEntity
        {
            PartitionKey = normalizedUserId,
            RowKey = normalizedRoomId,
            OriginalRoomId = roomId, // Preserve original for display
            CompletedAt = DateTimeOffset.UtcNow
        };

        // Upsert: insert or update (idempotent)
        await _tableClient.UpsertEntityAsync(entity, TableUpdateMode.Replace);
    }

    public async Task<bool> IsRoomCompletedAsync(string userId, string roomId)
    {
        var normalizedUserId = TableKeyNormalizer.NormalizeUserId(userId);
        var normalizedRoomId = TableKeyNormalizer.NormalizeRoomId(roomId);

        try
        {
            var response = await _tableClient.GetEntityAsync<RoomProgressEntity>(
                normalizedUserId,
                normalizedRoomId
            );
            return response.Value != null;
        }
        catch (RequestFailedException ex) when (ex.Status == 404)
        {
            return false;
        }
    }
}
