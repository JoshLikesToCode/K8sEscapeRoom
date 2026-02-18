# Escape Room: Access Denied

The application pod runs but crashes when it tries to talk to the cluster. It wants to do something but Kubernetes won't let it.

## Your Mission

1. Identify what the application is trying to do
2. Understand why it's failing
3. Fix the configuration so the application can function

## Success Criteria

- The pod shows "SUCCESS: Pod listing completed!" in its logs
- The pod remains in `Running` state (not failing/restarting)

## Getting Started

```bash
# Check the pod status
kubectl get pods -n escape-room-rbac-denied

# Check the logs to see what's happening
kubectl logs -l app=escape-app -n escape-room-rbac-denied
```

## Namespace

All resources are in the `escape-room-rbac-denied` namespace.

Good luck, engineer. The app knows what it wants to do, but Kubernetes won't let it.
