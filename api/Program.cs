using K8sEscapeRoom.Api.Services.Auth;
using K8sEscapeRoom.Api.Services.Storage;
using Microsoft.Azure.Functions.Worker;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;

var host = new HostBuilder()
    .ConfigureFunctionsWebApplication()
    .ConfigureServices(services =>
    {
        services.AddApplicationInsightsTelemetryWorkerService();
        services.ConfigureFunctionsApplicationInsights();

        // Auth service: use dev mock or SWA auth based on environment
        var isDevelopment = Environment.GetEnvironmentVariable("AZURE_FUNCTIONS_ENVIRONMENT") == "Development"
                         || Environment.GetEnvironmentVariable("FUNCTIONS_ENVIRONMENT") == "Development";

        // Always use real SWA auth service (parses x-ms-client-principal header)
        // In dev without SWA, requests will be unauthenticated unless header is provided
        services.AddSingleton<IAuthService, StaticWebAppsAuthService>();

        // Storage: Use Table Storage if connection string is configured, otherwise in-memory for dev
        var tablesConnectionString = Environment.GetEnvironmentVariable("TABLES_CONNECTION_STRING");
        var progressTableName = Environment.GetEnvironmentVariable("TABLES_TABLE_NAME");
        var attemptsTableName = Environment.GetEnvironmentVariable("ATTEMPTS_TABLE_NAME");

        if (!string.IsNullOrEmpty(tablesConnectionString))
        {
            services.AddSingleton<IProgressStorage>(new TableProgressStorage(tablesConnectionString, progressTableName));
            services.AddSingleton<IAttemptStorage>(new TableAttemptStorage(tablesConnectionString, attemptsTableName));
        }
        else if (isDevelopment)
        {
            // Fall back to in-memory storage in development only
            services.AddSingleton<IProgressStorage, InMemoryProgressStorage>();
            services.AddSingleton<IAttemptStorage, InMemoryAttemptStorage>();
        }
        else
        {
            // In production, missing connection string is a configuration error
            throw new InvalidOperationException(
                "TABLES_CONNECTION_STRING environment variable is required in production. " +
                "Set it to your Azure Table Storage or Cosmos DB Table API connection string.");
        }
    })
    .Build();

host.Run();
