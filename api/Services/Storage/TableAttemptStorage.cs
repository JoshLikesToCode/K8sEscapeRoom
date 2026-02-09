using Azure;
using Azure.Data.Tables;
using K8sEscapeRoom.Api.Models;

namespace K8sEscapeRoom.Api.Services.Storage;

/// <summary>
/// Azure Table Storage implementation for attempt storage.
/// Uses PartitionKey = UserId, RowKey = RoomId (last attempt per user+room).
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
        var attempt = new AttemptEntity(
            EscapeTableKey(userId),
            EscapeTableKey(roomId),
            nonce,
            ttl
        );

        // Upsert: replace any existing attempt for this user+room
        await _tableClient.UpsertEntityAsync(attempt, TableUpdateMode.Replace);
        return attempt;
    }

    public async Task<AttemptEntity?> GetAttemptAsync(string userId, string roomId)
    {
        try
        {
            var response = await _tableClient.GetEntityAsync<AttemptEntity>(
                EscapeTableKey(userId),
                EscapeTableKey(roomId)
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
