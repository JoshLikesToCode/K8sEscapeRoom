# K8s Escape Room Web

Next.js web application for the K8s Escape Room game-like experience.

## Overview

This is the hosted frontend for K8s Escape Room. It provides:
- Room browser and progress tracking
- Proof token verification
- Leaderboards and achievements

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

## Architecture

See [docs/Hosting.md](../docs/Hosting.md) for the full hosting architecture.

The web app communicates with the `/api` Azure Functions backend for:
- User authentication
- Progress tracking
- Proof token validation
