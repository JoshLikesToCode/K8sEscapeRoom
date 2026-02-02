# Escape Room: Secret Missing

The application pod is stuck and cannot start. The container won't even begin running.

## Your Mission

1. Identify why the pod cannot start
2. Determine what Kubernetes resource is missing
3. Create the missing resource so the pod runs successfully

## Success Criteria

- The pod `escape-app` is in `Running` state
- The pod shows "Application started successfully!" in its logs

## Getting Started

```bash
# Check the pod status
kubectl get pods -n escape-room-secret-missing

# You'll see something like:
# NAME         READY   STATUS                       RESTARTS   AGE
# escape-app   0/1     CreateContainerConfigError   0          30s
```

## Namespace

All resources are in the `escape-room-secret-missing` namespace.

Good luck, engineer. The application needs its secrets to start.
