# K8s Escape Room Web

Next.js web application for the K8s Escape Room game-like experience.

## Overview

This is the hosted frontend for K8s Escape Room. It provides:
- Room browser and progress tracking
- Proof token verification (coming soon)
- Leaderboards and achievements (coming soon)

**Important:** This site never touches your kubeconfig or cluster.
You run kubectl commands locally on your own cluster.

## Development

```bash
# Install dependencies
npm install

# Run development server
npm run dev

# Build for production
npm run build

# Start production server
npm start
```

### Development Authentication

By default, the app requires Azure Static Web Apps authentication. In local development, you will be unauthenticated unless:

1. **Option A: Enable mock auth** (easiest for local development)
   ```bash
   NEXT_PUBLIC_DEV_AUTH=1 npm run dev
   ```
   This creates a mock "DevUser" so you can test progress tracking locally.

2. **Option B: Use SWA CLI** (for full auth testing)
   ```bash
   npm install -g @azure/static-web-apps-cli
   swa start http://localhost:3000 --api-location ../api
   ```
   This proxies through SWA CLI which provides real auth endpoints.

### API Configuration

The web app expects the API to be available at `/api/*`. In production, Azure Static Web Apps routes this automatically. In development:

- **With SWA CLI**: API is served automatically
- **Without SWA CLI**: Run the Azure Functions API separately on port 7071 and configure a proxy, or use mock auth mode

## Architecture

See [docs/Hosting.md](../docs/Hosting.md) for the full hosting architecture.

The web app communicates with the `/api` Azure Functions backend for:
- User authentication (via Azure Static Web Apps EasyAuth)
- Progress tracking (Azure Table Storage)
- Proof token validation (coming soon)
