# Escape Room: Uncharted Config

The application pod is stuck and cannot start. Something it needs was never created.

## Your Mission

1. Identify why the pod cannot start
2. Figure out what it needs
3. Fix the problem so the pod runs successfully

## Success Criteria

- The pod `escape-app` is in `Running` state
- The pod shows "Application configured successfully!" in its logs

## Getting Started

```bash
# Check the pod status
kubectl get pods -n escape-room-uncharted-config

# You'll see something like:
# NAME         READY   STATUS                       RESTARTS   AGE
# escape-app   0/1     CreateContainerConfigError   0          30s
```

## Namespace

All resources are in the `escape-room-uncharted-config` namespace.

Good luck, engineer. Something is missing, and the app won't start without it.
