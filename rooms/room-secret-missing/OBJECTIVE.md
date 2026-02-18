# Escape Room: The Vault is Empty

The application pod is stuck and cannot start. It's looking for something that should exist but doesn't.

## Your Mission

1. Identify why the pod cannot start
2. Figure out what it needs
3. Fix the problem so the pod runs successfully

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

Good luck, engineer. The application won't start without what it's looking for.
