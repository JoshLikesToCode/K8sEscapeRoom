using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Azure.Functions.Worker;
using Microsoft.Extensions.Logging;

namespace K8sEscapeRoom.Api.Functions;

/// <summary>
/// Health check endpoint for the API.
/// </summary>
public class HealthCheck
{
    private readonly ILogger<HealthCheck> _logger;

    public HealthCheck(ILogger<HealthCheck> logger)
    {
        _logger = logger;
    }

    [Function("HealthCheck")]
    public IActionResult Run(
        [HttpTrigger(AuthorizationLevel.Anonymous, "get", Route = "health")] HttpRequest req)
    {
        _logger.LogInformation("Health check requested");

        return new OkObjectResult(new
        {
            status = "healthy",
            version = "0.1.0",
            timestamp = DateTime.UtcNow
        });
    }
}
