using Azure;
using Azure.Data.Tables;
using K8sEscapeRoom.Api.Models;

namespace K8sEscapeRoom.Api.Services.Storage;

/// <summary>
/// Azure Table Storage implementation for attempt storage.
/// Uses PartitionKey = UserId, RowKey = RoomId (last attempt per user+room).
/// All keys are normalized consistently using TableKeyNormalizer.
/// </summary>
public class TableAttemptStorage : IAttemptStorage
{
    private readonly TableClient _tableClient;
    private const string DefaultTableName = "K8sEscapeRoomAttempts";

    public TableAttemptStorage(string connectionString, string? tableName = null)
    {
        var serviceClient = new TableServiceClient(connectionString);
        _tableClient = serviceClient.GetTableClient(tableName ?? DefaultTableName);
        _tableClient.CreateIfNotExists();
    }

    public async Task<AttemptEntity> CreateAttemptAsync(string userId, string roomId, string nonce, TimeSpan ttl)
    {
        var normalizedUserId = TableKeyNormalizer.NormalizeUserId(userId);
        var normalizedRoomId = TableKeyNormalizer.NormalizeRoomId(roomId);

        var attempt = new AttemptEntity
        {
            PartitionKey = normalizedUserId,
            RowKey = normalizedRoomId,
            OriginalRoomId = roomId, // Preserve original for API responses
            Nonce = nonce,
            IssuedAtUtc = DateTimeOffset.UtcNow,
            ExpiresAtUtc = DateTimeOffset.UtcNow.Add(ttl),
            IsUsed = false,
            UsedAtUtc = null
        };

        // Upsert: replace any existing attempt for this user+room
        await _tableClient.UpsertEntityAsync(attempt, TableUpdateMode.Replace);
        return attempt;
    }

    public async Task<AttemptEntity?> GetAttemptAsync(string userId, string roomId)
    {
        var normalizedUserId = TableKeyNormalizer.NormalizeUserId(userId);
        var normalizedRoomId = TableKeyNormalizer.NormalizeRoomId(roomId);

        try
        {
            var response = await _tableClient.GetEntityAsync<AttemptEntity>(
                normalizedUserId,
                normalizedRoomId
            );
            return response.Value;
        }
        catch (RequestFailedException ex) when (ex.Status == 404)
        {
            return null;
        }
    }

    public async Task MarkAttemptUsedAsync(string userId, string roomId)
    {
        var attempt = await GetAttemptAsync(userId, roomId);
        if (attempt != null)
        {
            attempt.IsUsed = true;
            attempt.UsedAtUtc = DateTimeOffset.UtcNow;
            await _tableClient.UpsertEntityAsync(attempt, TableUpdateMode.Replace);
        }
    }
}
