# Escape Room: Room Full

The application pod is waiting in line but never gets scheduled.

## Your Mission

1. Identify why the pod can't be scheduled
2. Figure out what's blocking it
3. Fix the configuration so the pod can run

## Success Criteria

- The pod `escape-app` is in `Running` state
- The nginx container is serving traffic on port 80

## Getting Started

```bash
# Check the pod status
kubectl get pods -n escape-room-full

# You'll see something like:
# NAME         READY   STATUS    RESTARTS   AGE
# escape-app   0/1     Pending   0          2m
```

Notice that READY is 0/1 and STATUS is Pending - the pod hasn't even started!

## Namespace

All resources are in the `escape-room-full` namespace.

Good luck, engineer. The scheduler awaits your fix.
