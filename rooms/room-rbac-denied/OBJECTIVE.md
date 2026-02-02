# Escape Room: RBAC Denied

The application pod is trying to interact with the Kubernetes API but keeps failing with permission errors. The pod runs but the application cannot perform its intended function.

## Your Mission

1. Identify what the application is trying to do
2. Understand why it's being denied
3. Grant the necessary permissions so the application can function

## Success Criteria

- The pod `escape-app` shows "SUCCESS: Pod listing completed!" in its logs
- The pod remains in `Running` state (not failing/restarting)

## Getting Started

```bash
# Check the pod status
kubectl get pods -n escape-room-rbac-denied

# Check the logs to see what's happening
kubectl logs escape-app -n escape-room-rbac-denied
```

## Namespace

All resources are in the `escape-room-rbac-denied` namespace.

Good luck, engineer. The app knows what it wants to do, but Kubernetes won't let it.
