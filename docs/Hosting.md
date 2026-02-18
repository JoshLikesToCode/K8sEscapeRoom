# Hosting Architecture

This document describes the hosting model for the K8s Escape Room web experience.

## Overview

K8s Escape Room uses a **Bring Your Own Cluster (BYOC)** model. The hosted website
provides a game-like interface for tracking progress, but **never touches your
Kubernetes cluster or kubeconfig**.

```
┌─────────────────────────────────────────────────────────────────────┐
│                         User's Machine                              │
│  ┌─────────────┐    ┌─────────────┐    ┌─────────────────────────┐ │
│  │   Browser   │    │   kubectl   │    │  kind/minikube/etc     │ │
│  │  (Web App)  │    │   (CLI)     │────│  (Local Cluster)       │ │
│  └──────┬──────┘    └──────┬──────┘    └─────────────────────────┘ │
│         │                  │                                        │
└─────────┼──────────────────┼────────────────────────────────────────┘
          │                  │
          │ HTTPS            │ Local only
          │ (progress only)  │ (never leaves machine)
          ▼                  │
┌─────────────────────┐      │
│   K8sEscapeRoom     │      │
│   Hosted Service    │      │
│  ┌───────────────┐  │      │
│  │   Web App     │  │      │
│  │  (Next.js)    │  │      │
│  └───────┬───────┘  │      │
│          │          │      │
│  ┌───────▼───────┐  │      │
│  │     API       │  │      │
│  │ (Azure Func)  │  │      │
│  └───────┬───────┘  │      │
│          │          │      │
│  ┌───────▼───────┐  │      │
│  │   Database    │  │      │
│  │  (Progress)   │  │      │
│  └───────────────┘  │      │
└─────────────────────┘      │
                             │
        ┌────────────────────┘
        │
        ▼
   Your cluster stays
   completely private

```

## Security Principles

### 1. No Kubeconfig Access

The hosted service **never** receives, stores, or processes kubeconfig files.
Users run all `kubectl` commands locally on their own machines.

### 2. No Cluster Connectivity

The hosted service cannot connect to user clusters. There are:
- No webhook integrations
- No agent installations
- No API server access

### 3. Proof Token Model

To verify room completion, users generate **proof tokens** locally:

```bash
# User runs escape verification locally
make room-verify ROOM=room-groundhog-deploy

# On success, a proof token is displayed
# ✓ Room escaped! Proof token: eyJ0eXAi...

# User pastes token into web UI to claim credit
```

Proof tokens are:
- Generated locally by the CLI
- Signed with room-specific data
- Verified by the API without cluster access
- Time-limited to prevent sharing

### 4. Progress Tracking Only

The hosted service stores only:
- User account information (email, display name)
- Room completion status (which rooms, when)
- Proof tokens (for verification)
- Optional: leaderboard rankings

## Components

### Web App (`/web`)

Next.js TypeScript application providing:
- Room browser with objectives and hints
- Progress dashboard
- Proof token submission
- Leaderboards (optional)

Deployed to: Azure Static Web Apps, Vercel, or similar

### API (`/api`)

.NET 8 Azure Functions providing:
- User authentication
- Progress tracking
- Proof token validation
- Leaderboard queries

Deployed to: Azure Functions

### CLI (`/src/K8sEscapeRoom.Cli`)

.NET 8 console application that:
- Wraps Makefile targets
- Runs entirely locally
- Generates proof tokens on escape
- Never communicates with hosted service

## Data Flow

### Starting a Room

1. User browses rooms on web app
2. User sees objective and hints
3. User runs locally:
   ```bash
   make room-apply ROOM=room-groundhog-deploy
   ```
4. Web app has no involvement in cluster changes

### Escaping a Room

1. User debugs and fixes the room locally
2. User verifies escape:
   ```bash
   make room-verify ROOM=room-groundhog-deploy
   ```
3. CLI generates proof token locally
4. User copies token to web app
5. API validates token and records progress

### Proof Token Structure

```json
{
  "room": "room-groundhog-deploy",
  "timestamp": "2025-02-05T12:00:00Z",
  "checksum": "sha256:abc123...",
  "signature": "..."
}
```

The checksum is derived from:
- Room name
- Timestamp
- Local machine identifier (optional)
- Secret salt (embedded in CLI)

This prevents:
- Token fabrication without actually escaping
- Token sharing between users (optional)
- Token reuse after expiration

## Self-Hosting

The entire stack can be self-hosted:

1. **Web App**: Deploy to any static hosting (Vercel, Netlify, S3)
2. **API**: Deploy to Azure Functions, AWS Lambda, or container
3. **Database**: Any SQL or NoSQL database

Environment variables required:
- `API_URL`: Backend API endpoint
- `DATABASE_CONNECTION`: Database connection string
- `JWT_SECRET`: For user authentication

## Privacy

- No telemetry is sent from local clusters
- No cluster metadata is collected
- Users can play entirely offline with CLI
- Web features are optional enhancements

## Future Considerations

- GitHub OAuth for authentication
- Team/organization support
- Custom room hosting
- Room creation tools
