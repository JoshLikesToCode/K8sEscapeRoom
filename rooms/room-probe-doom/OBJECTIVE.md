# Escape Room: Probe Doom

The application keeps restarting. It seems to start up fine, but then Kubernetes kills it repeatedly.

## Your Mission

1. Identify why the pod keeps restarting
2. Investigate what's triggering the restarts
3. Fix the configuration so the pod stays running

## Success Criteria

- The pod `escape-app` is in `Running` state with `Ready` condition
- The pod is stable (not restarting)
- The restart count stops increasing

## Getting Started

```bash
# Check the pod status - notice the restart count
kubectl get pods -n escape-room-probe-doom

# You might see something like:
# NAME         READY   STATUS    RESTARTS      AGE
# escape-app   0/1     Running   3 (5s ago)    30s
```

## Namespace

All resources are in the `escape-room-probe-doom` namespace.

Good luck, engineer. Something keeps killing your app, and it's not the app's fault.
