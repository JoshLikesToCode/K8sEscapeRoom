# Escape Room: 404: Room Not Found

The container never even starts — something is missing before it can run.

## Your Mission

1. Identify why the container can't start
2. Figure out what's wrong
3. Fix the pod so it runs successfully

## Success Criteria

- The pod `escape-app` is in `Running` state
- The nginx container is serving traffic on port 80

## Getting Started

```bash
# Check the pod status
kubectl get pods -n escape-room-404-not-found

# You'll see something like:
# NAME         READY   STATUS             RESTARTS   AGE
# escape-app   0/1     ImagePullBackOff   0          2m
```

## Namespace

All resources are in the `escape-room-404-not-found` namespace.

Good luck, engineer. Every second counts.
