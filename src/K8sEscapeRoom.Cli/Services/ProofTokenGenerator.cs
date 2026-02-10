using System.Security.Cryptography;
using System.Text;

namespace K8sEscapeRoom.Cli.Services;

/// <summary>
/// Generates proof tokens for room completion verification.
/// Token format: K8SER|roomId|nonce|timestamp|sha256
/// </summary>
public static class ProofTokenGenerator
{
    private const string TokenPrefix = "K8SER";

    /// <summary>
    /// Generate a proof token for a completed room.
    /// </summary>
    /// <param name="roomId">The room ID</param>
    /// <param name="nonce">The nonce from the attempt</param>
    /// <returns>A proof token string</returns>
    public static string Generate(string roomId, string nonce)
    {
        // Use Unix epoch seconds for timestamp
        var timestamp = DateTimeOffset.UtcNow.ToUnixTimeSeconds();

        // Compute SHA256 hash of: roomId|nonce|timestamp
        var hashInput = $"{roomId}|{nonce}|{timestamp}";
        var hashBytes = SHA256.HashData(Encoding.UTF8.GetBytes(hashInput));
        var hash = Convert.ToHexString(hashBytes).ToLowerInvariant();

        // Format: K8SER|roomId|nonce|timestamp|sha256
        return $"{TokenPrefix}|{roomId}|{nonce}|{timestamp}|{hash}";
    }
}
