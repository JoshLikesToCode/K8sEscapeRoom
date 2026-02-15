# Escape Room: CrashLoopBackOff - Missing Environment Variable

The application pod is stuck in CrashLoopBackOff and cannot start.

## Your Mission

1. Identify why the pod is crashing
2. Determine what configuration is missing
3. Fix the deployment so the pod runs successfully

## Success Criteria

- The `escape-app` pod is in `Running` state
- The pod has been running for at least 30 seconds without restarting

## Getting Started

```bash
# Check the pod status
kubectl get pods -n escape-room-crashloop-env

# You'll see something like:
# NAME                          READY   STATUS             RESTARTS   AGE
# escape-app-5d4f7b8c9-x2k7p   0/1     CrashLoopBackOff   3          2m
```

## Namespace

All resources are in the `escape-room-crashloop-env` namespace.

Good luck, engineer. The clock is ticking.
