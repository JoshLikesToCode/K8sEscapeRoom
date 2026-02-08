# K8s Escape Room API

.NET 8 Azure Functions backend for the K8s Escape Room web experience.

## Overview

This API provides backend services for the hosted web experience:
- User authentication (future)
- Progress tracking (future)
- Proof token validation (future)

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

| Method | Route | Description |
|--------|-------|-------------|
| GET | `/api/health` | Health check endpoint |

More endpoints will be added as features are implemented.

## Project Structure

```
api/
├── Functions/           # HTTP-triggered functions
│   └── HealthCheck.cs
├── K8sEscapeRoom.Api.csproj
├── Program.cs           # Host configuration
├── host.json            # Functions runtime config
└── local.settings.template.json  # Template for local settings
```

## Configuration

Runtime configuration is in `host.json`. Local development settings go in `local.settings.json` (not committed - copy from template).

## Architecture

See [docs/Hosting.md](../docs/Hosting.md) for the full hosting architecture.
