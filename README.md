# K8sEscapeRoom

A scenario-driven Kubernetes "escape room" where engineers debug real cluster failure modes to sharpen their troubleshooting skills.

## What is K8sEscapeRoom?

K8sEscapeRoom presents you with intentionally broken Kubernetes deployments. Your mission: diagnose the problem using `kubectl` and fix it to "escape" each room.

Each room represents a common Kubernetes failure pattern:
- **CrashLoopBackOff** - Pods crashing on startup
- **ImagePullBackOff** - Container images that can't be pulled
- **Pending** - Pods that can't be scheduled

This is **not** a simulation. You work with a real Kubernetes cluster (via kind) and use real tools.

## Why?

Kubernetes troubleshooting is a critical skill that's hard to practice without experiencing real failures. K8sEscapeRoom provides:

- **Safe practice environment** - Break things without consequences
- **Real tooling** - Use actual `kubectl` commands, not abstractions
- **Progressive hints** - Learn at your own pace
- **Reproducible scenarios** - Reset and retry as needed

## Prerequisites

| Tool | Version | Installation |
|------|---------|--------------|
| Docker | 20.10+ | [Get Docker](https://docs.docker.com/get-docker/) |
| kind | 0.20+ | [Install kind](https://kind.sigs.k8s.io/docs/user/quick-start/#installation) |
| kubectl | 1.28+ | [Install kubectl](https://kubernetes.io/docs/tasks/tools/) |
| .NET 8 | (optional) | [Download .NET](https://dotnet.microsoft.com/download) |

Verify your setup:
```bash
make tools-check
```

## Quickstart

```bash
# 1. Create the cluster
make cluster-up

# 2. See available rooms
make room-list

# 3. Enter your first escape room
make room-apply ROOM=room-groundhog-deploy

# 4. Investigate!
kubectl get pods -n escape-room-groundhog-deploy
kubectl describe pod escape-app -n escape-room-groundhog-deploy
kubectl logs escape-app -n escape-room-groundhog-deploy

# 5. When stuck, get help
make room-objective ROOM=room-groundhog-deploy  # What to achieve
make room-hint ROOM=room-groundhog-deploy       # Progressive hints
make room-solution ROOM=room-groundhog-deploy   # Full solution

# 6. Verify your fix
make room-escape-test ROOM=room-groundhog-deploy  # Validates you escaped!

# 7. Reset and try again (or move to next room)
make room-reset ROOM=room-groundhog-deploy
```

## Available Rooms

| Room | Failure Mode | Difficulty |
|------|--------------|------------|
| `room-groundhog-deploy` | CrashLoopBackOff - Missing environment variable | Beginner |
| `room-404-not-found` | ImagePullBackOff - Invalid image tag | Beginner |
| `room-full` | Pending - Resource requests exceed capacity | Beginner |

## Commands Reference

### Makefile Targets

```bash
make help              # Show all available commands
make tools-check       # Verify prerequisites are installed
make cluster-up        # Create the kind cluster
make cluster-down      # Delete the kind cluster
make cluster-status    # Show cluster status
make room-list         # List all available rooms
make room-new ROOM=<name>        # Create a new room from template
make room-apply ROOM=<name>      # Enter a room (apply broken state)
make room-reset ROOM=<name>      # Reset a room (delete resources)
make room-test ROOM=<name>       # Validate room is in broken state
make room-escape-test ROOM=<name> # Validate you escaped (fixed it)
make room-objective ROOM=<name>  # Show room objective
make room-hint ROOM=<name>       # Show hints
make room-solution ROOM=<name>   # Show solution
```

### CLI (Optional)

If you have .NET 8 installed:

```bash
# Build the CLI
dotnet build src/K8sEscapeRoom.Cli

# Run via dotnet
dotnet run --project src/K8sEscapeRoom.Cli -- room list
dotnet run --project src/K8sEscapeRoom.Cli -- cluster up
dotnet run --project src/K8sEscapeRoom.Cli -- room apply room-groundhog-deploy

# Or install globally
dotnet tool install --global --add-source ./src/K8sEscapeRoom.Cli K8sEscapeRoom.Cli
escape room list
```

## kubectl Debugging Cheat Sheet

### Pod Status Investigation

```bash
# Overview of pods
kubectl get pods -n <namespace>
kubectl get pods -n <namespace> -o wide  # More details

# Detailed pod information
kubectl describe pod <pod-name> -n <namespace>

# Container logs
kubectl logs <pod-name> -n <namespace>
kubectl logs <pod-name> -n <namespace> --previous  # Previous container logs
kubectl logs <pod-name> -n <namespace> -f          # Follow/stream logs
```

### Common Status Meanings

| Status | Meaning | First Steps |
|--------|---------|-------------|
| `Pending` | Pod cannot be scheduled | Check events, node resources, taints |
| `ContainerCreating` | Image pulling or volume mounting | Check image name, secrets, PVCs |
| `Running` | Container is running | Check logs if behavior is wrong |
| `CrashLoopBackOff` | Container keeps crashing | Check logs, describe pod |
| `ImagePullBackOff` | Cannot pull container image | Check image name, registry auth |
| `Error` | Container exited with error | Check logs for error message |

### Resource Investigation

```bash
# Node capacity and allocation
kubectl describe nodes
kubectl top nodes  # Requires metrics-server

# Events (cluster-wide or namespaced)
kubectl get events -n <namespace> --sort-by='.lastTimestamp'

# Resource usage
kubectl top pods -n <namespace>  # Requires metrics-server
```

### Quick Fixes

```bash
# Delete and recreate a pod
kubectl delete pod <pod-name> -n <namespace>
kubectl apply -f <manifest.yaml>

# Edit a resource directly (opens in $EDITOR)
kubectl edit pod <pod-name> -n <namespace>

# Quick pod creation for testing
kubectl run test --image=nginx --rm -it -- /bin/sh
```

## Project Structure

```
K8sEscapeRoom/
├── Makefile                 # Primary interface for all commands
├── scripts/                 # Bash scripts for automation
│   ├── tools-check.sh       # Verify prerequisites
│   ├── kind-create.sh       # Create kind cluster
│   ├── kind-delete.sh       # Delete kind cluster
│   ├── room-apply.sh        # Apply a room's broken state
│   ├── room-reset.sh        # Reset a room
│   ├── room-test.sh         # Test room is in expected state
│   ├── room-new.sh          # Scaffold a new room
│   └── test-helpers.sh      # Shared test utilities
├── kind/
│   └── cluster.yaml         # Kind cluster configuration
├── rooms/                   # Escape room definitions
│   └── room-<name>/
│       ├── app.yaml         # Kubernetes manifests (broken)
│       ├── OBJECTIVE.md     # What you need to achieve
│       ├── HINTS.md         # Progressive hints
│       ├── SOLUTION.md      # Full solution
│       ├── tests.sh         # Validates broken state
│       └── escape-tests.sh  # Validates fixed state (optional)
├── src/
│   └── K8sEscapeRoom.Cli/   # Optional .NET CLI wrapper
├── tests/
│   └── K8sEscapeRoom.Cli.Tests/  # CLI unit tests
└── .github/workflows/
    └── ci.yml               # CI pipeline
```

## Web Development (Hosted Experience)

The project includes an optional hosted web experience for progress tracking. See [docs/Hosting.md](docs/Hosting.md) for architecture details.

### Running Web + API Locally

```bash
# Terminal 1: Start the API (requires Azure Functions Core Tools)
cd api
cp local.settings.template.json local.settings.json
func start
# API runs at http://localhost:7071

# Terminal 2: Start the web app
cd web
npm install
npm run dev
# Web runs at http://localhost:3000
```

### Project Components

| Component | Path | Technology |
|-----------|------|------------|
| Escape Rooms | `/rooms` | Kubernetes manifests, shell scripts |
| CLI | `/src/K8sEscapeRoom.Cli` | .NET 8 |
| Web Frontend | `/web` | Next.js 14, TypeScript, Tailwind |
| API Backend | `/api` | .NET 8 Azure Functions |

## Creating New Rooms

Use the room generator to scaffold a new room:

```bash
make room-new ROOM=room-my-scenario
```

This creates all required files with templates:
- `app.yaml` - Kubernetes manifest (add your intentional bug)
- `OBJECTIVE.md` - What success looks like
- `HINTS.md` - Progressive hints (Level 1-4)
- `SOLUTION.md` - Complete diagnosis and fix
- `tests.sh` - Validates the broken state
- `escape-tests.sh` - Validates the fixed state

Then customize each file and test your room:

```bash
# Apply and verify the broken state
make room-apply ROOM=room-my-scenario
make room-test ROOM=room-my-scenario

# Fix it yourself and verify the escape
make room-escape-test ROOM=room-my-scenario

# Reset when done
make room-reset ROOM=room-my-scenario
```

See [docs/RoomContract.md](docs/RoomContract.md) for detailed requirements.

## Philosophy

- **Real Kubernetes** - No simulations or mocks
- **kubectl is the interface** - We don't hide Kubernetes from you
- **Learn by doing** - Hands-on troubleshooting builds muscle memory
- **Progressive disclosure** - Hints guide without giving away answers
- **Reproducible** - Every scenario can be reset and retried

## Contributing

Contributions welcome! Ideas for new rooms:
- NetworkPolicy blocking traffic
- ConfigMap/Secret mounting failures
- Liveness/Readiness probe failures
- PersistentVolumeClaim issues
- Service selector mismatches
- Init container failures

## License

MIT
