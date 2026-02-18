# Deploy to Azure Static Web Apps

This guide covers deploying the K8sEscapeRoom web app and API to Azure Static Web Apps (SWA).

## Architecture

```
Azure Static Web Apps
├── Web (Next.js 14, App Router)    ← static + SSR via managed hosting
├── API  (.NET 8 Azure Functions)   ← managed Functions backend
└── Auth (SWA built-in)             ← GitHub OAuth via /.auth/*
```

SWA handles routing between the frontend and API automatically. The Next.js API proxy route (`/api/[...path]`) is only used during local development.

## SWA Build Configuration

For the GitHub Actions workflow (`deploy.yml`), use these settings:

| Setting           | Value  | Notes                                      |
| ----------------- | ------ | ------------------------------------------ |
| `app_location`    | `web`  | Next.js app root                           |
| `api_location`    | `api`  | .NET Azure Functions project               |
| `output_location` | (blank) | SWA's Oryx builder detects Next.js automatically |

> **Why blank `output_location`?** SWA uses [Oryx](https://github.com/microsoft/Oryx) to build Next.js apps. It runs `npm run build` and knows where Next.js puts its output. Setting this explicitly can cause double-build or wrong directory issues.

## Environment Variables

Set these in the SWA resource (Settings > Configuration):

| Variable                   | Required | Description                         |
| -------------------------- | -------- | ----------------------------------- |
| `TABLES_CONNECTION_STRING` | Yes      | Azure Table Storage connection      |
| `TABLES_TABLE_NAME`        | No       | Table name (default: `UserProgress`)|
| `ATTEMPTS_TABLE_NAME`      | No       | Attempts table (default: `Attempts`)|

## Routing

`web/staticwebapp.config.json` handles:

- **API access**: `/api/*` requests are routed to the managed Azure Functions backend, open to both anonymous and authenticated users.
- **Security headers**: `X-Content-Type-Options: nosniff` and `X-Frame-Options: DENY` on all responses.

> **No `navigationFallback` needed.** SWA's managed Next.js support handles SSR routing natively — Next.js serves all pages through its own router, so a SPA-style fallback rewrite would interfere. Deep links like `/play/room-crashloop-env` work because Next.js handles them server-side.

## Local Development with SWA CLI

```bash
# Install SWA CLI
npm install -g @azure/static-web-apps-cli

# Terminal 1: Start the API
cd api && func start

# Terminal 2: Start Next.js dev server
cd web && npm run dev

# Terminal 3: Start SWA proxy (ties them together)
swa start http://localhost:3000 --api-location http://localhost:7071
```

This gives you:
- SWA auth emulation at `/.auth/login/github`
- API routing matching production
- `x-ms-client-principal` header injection

## GitHub Actions Deployment

The workflow at `.github/workflows/deploy.yml` deploys on push to `main`. It uses the `Azure/static-web-apps-deploy@v1` action with a deployment token stored as a repository secret (`AZURE_STATIC_WEB_APPS_API_TOKEN`).

### Setup Steps

1. Create an SWA resource in the Azure Portal.
2. Copy the deployment token from the SWA resource overview.
3. Add it as a GitHub repository secret named `AZURE_STATIC_WEB_APPS_API_TOKEN`.
4. Push to `main` — the workflow runs automatically.

## Notes on Next.js 14 + SWA

- SWA has managed Next.js support including hybrid rendering (static + SSR).
- The `output: 'standalone'` setting in `next.config.js` is compatible with SWA's managed hosting.
- Room data is pre-generated at build time (`rooms.json`), so the deployed app has no filesystem dependency on the `rooms/` directory.
- The `prebuild` script in `package.json` runs `generate-rooms` automatically before `next build`.
