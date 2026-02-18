# K8s Escape Room API

.NET 8 Azure Functions backend for the K8s Escape Room web experience.

## Overview

This API provides backend services for the hosted web experience:
- User authentication (via Azure Static Web Apps EasyAuth)
- Progress tracking (Azure Table Storage)
- Proof token validation

**Important:** This API never receives kubeconfigs or cluster access.
It only validates proof tokens that users generate locally.

## Requirements

| Dependency | Version | Notes |
|------------|---------|-------|
| .NET SDK | 8.0+ | [Download](https://dotnet.microsoft.com/download/dotnet/8.0) |
| Azure Functions Core Tools | v4.x | [Install guide](https://docs.microsoft.com/azure/azure-functions/functions-run-local) |
| Azure Functions Runtime | v4 | Configured in `host.json` |

### Installing Azure Functions Core Tools

```bash
# macOS
brew tap azure/functions
brew install azure-functions-core-tools@4

# Windows
winget install Microsoft.Azure.FunctionsCoreTools

# Linux (Ubuntu/Debian)
curl https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > microsoft.gpg
sudo mv microsoft.gpg /etc/apt/trusted.gpg.d/microsoft.gpg
sudo sh -c 'echo "deb [arch=amd64] https://packages.microsoft.com/repos/microsoft-ubuntu-$(lsb_release -cs)-prod $(lsb_release -cs) main" > /etc/apt/sources.list.d/dotnetdev.list'
sudo apt-get update
sudo apt-get install azure-functions-core-tools-4
```

## Local Development

### 1. Create local settings

```bash
# Copy the template
cp local.settings.template.json local.settings.json

# Edit as needed (the defaults work for local dev)
```

### 2. Run the API

```bash
# Restore dependencies
dotnet restore

# Run with Azure Functions Core Tools (recommended)
func start

# The API will be available at http://localhost:7071
```

### 3. Test the health endpoint

```bash
curl http://localhost:7071/api/health
```

## Build & Publish

```bash
# Build
dotnet build

# Build release
dotnet build -c Release

# Publish for deployment
dotnet publish -c Release -o ./publish
```

## Endpoints

| Method | Route | Auth | Description |
|--------|-------|------|-------------|
| GET | `/api/health` | No | Health check endpoint |
| GET | `/api/me` | Yes | Get current user and completed rooms |
| POST | `/api/rooms/{roomId}/attempt` | Yes | Start a completion attempt, get nonce |
| POST | `/api/rooms/{roomId}/submit` | Yes | Submit proof token to complete room |
| POST | `/api/rooms/{roomId}/complete` | Yes | (Deprecated) Direct complete without proof |

### Proof Flow

1. **Start Attempt**: `POST /api/rooms/{roomId}/attempt`
   - Returns: `{ roomId, nonce, expiresAtUtc }`
   - Nonce expires after 30 minutes

2. **Generate Proof**: Run CLI command locally after fixing the room
   ```bash
   escape room proof <roomId> --nonce <nonce>
   ```
   - Runs escape-tests to verify fix
   - Outputs token: `K8SER|roomId|nonce|timestamp|sha256`

3. **Submit Proof**: `POST /api/rooms/{roomId}/submit`
   - Body: `{ "token": "K8SER|..." }`
   - Validates nonce, TTL, single-use, and hash
   - On success, marks room completed

### Authentication

In production, Azure Static Web Apps handles authentication via the `x-ms-client-principal` header. The API parses this header to get user identity.

In development without SWA:
- Requests without the header are treated as unauthenticated (401)
- To test authenticated endpoints, use a tool like [SWA CLI](https://azure.github.io/static-web-apps-cli/)

## Project Structure

```
api/
├── Functions/               # HTTP-triggered functions
│   ├── HealthCheck.cs       # Health check endpoint
│   ├── Me.cs                # GET /api/me
│   ├── StartAttempt.cs      # POST /api/rooms/{roomId}/attempt
│   ├── SubmitProof.cs       # POST /api/rooms/{roomId}/submit
│   └── CompleteRoom.cs      # POST /api/rooms/{roomId}/complete (deprecated)
├── Models/                  # Data models
│   ├── User.cs              # User and UserProgress records
│   ├── RoomProgress.cs      # Table entity for progress storage
│   └── AttemptEntity.cs     # Table entity for attempt tracking
├── Services/
│   ├── Auth/
│   │   └── StaticWebAppsAuth.cs  # SWA authentication parsing
│   └── Storage/
│       ├── IProgressStorage.cs      # Progress storage abstraction
│       ├── IAttemptStorage.cs       # Attempt storage abstraction
│       ├── InMemoryProgressStorage.cs  # Dev progress storage
│       ├── InMemoryAttemptStorage.cs   # Dev attempt storage
│       ├── TableProgressStorage.cs     # Azure Table progress storage
│       └── TableAttemptStorage.cs      # Azure Table attempt storage
├── Validation/
│   ├── RoomIdValidator.cs       # Room ID validation logic
│   └── ProofTokenValidator.cs   # Proof token parsing and verification
├── K8sEscapeRoom.Api.csproj
├── Program.cs               # Host configuration and DI
├── host.json                # Functions runtime config
└── local.settings.template.json  # Template for local settings
```

## Configuration

Runtime configuration is in `host.json`. Local development settings go in `local.settings.json` (not committed - copy from template).

### Environment Variables

| Variable | Required | Default | Description |
|----------|----------|---------|-------------|
| `TABLES_CONNECTION_STRING` | Prod only | - | Azure Table Storage or Cosmos DB Table API connection string |
| `TABLES_TABLE_NAME` | No | `K8sEscapeRoomProgress` | Table name for storing progress |
| `AZURE_FUNCTIONS_ENVIRONMENT` | No | - | Set to `Development` for local dev mode |

### Local Development Storage

In development mode (`AZURE_FUNCTIONS_ENVIRONMENT=Development`), if `TABLES_CONNECTION_STRING` is not set, the API uses in-memory storage. Progress will be lost on restart.

To use Azurite (local Azure Storage emulator):
```bash
# Install Azurite
npm install -g azurite

# Start Azurite
azurite --silent --location ./azurite-data

# Set connection string in local.settings.json
# "TABLES_CONNECTION_STRING": "UseDevelopmentStorage=true"
```

### Production Configuration

In production, `TABLES_CONNECTION_STRING` must be set. The API will fail to start without it.

## Architecture

See [docs/Hosting.md](../docs/Hosting.md) for the full hosting architecture.
