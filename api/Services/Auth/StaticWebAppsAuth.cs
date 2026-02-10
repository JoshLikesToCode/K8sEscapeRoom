using System.Text;
using System.Text.Json;
using K8sEscapeRoom.Api.Models;
using Microsoft.AspNetCore.Http;

namespace K8sEscapeRoom.Api.Services.Auth;

/// <summary>
/// Extracts user identity from Azure Static Web Apps auth headers
/// </summary>
public interface IAuthService
{
    /// <summary>
    /// Get the current user from request headers.
    /// Returns null if not authenticated.
    /// </summary>
    User? GetUser(HttpRequest request);
}

public class StaticWebAppsAuthService : IAuthService
{
    private const string ClientPrincipalHeader = "x-ms-client-principal";

    public User? GetUser(HttpRequest request)
    {
        // Check for SWA client principal header
        if (!request.Headers.TryGetValue(ClientPrincipalHeader, out var headerValue))
        {
            return null;
        }

        var principalData = headerValue.FirstOrDefault();
        if (string.IsNullOrEmpty(principalData))
        {
            return null;
        }

        try
        {
            // Decode base64 principal data
            var decoded = Convert.FromBase64String(principalData);
            var json = Encoding.UTF8.GetString(decoded);

            var principal = JsonSerializer.Deserialize<ClientPrincipal>(json, new JsonSerializerOptions
            {
                PropertyNameCaseInsensitive = true
            });

            if (principal == null || string.IsNullOrEmpty(principal.UserId))
            {
                return null;
            }

            return new User(
                principal.UserId,
                principal.UserDetails ?? principal.UserId,
                principal.IdentityProvider ?? "unknown"
            );
        }
        catch
        {
            return null;
        }
    }

    private record ClientPrincipal(
        string? IdentityProvider,
        string? UserId,
        string? UserDetails,
        IReadOnlyList<string>? UserRoles
    );
}

