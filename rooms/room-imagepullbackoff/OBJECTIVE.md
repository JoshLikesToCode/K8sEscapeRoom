# Escape Room: ImagePullBackOff - Invalid Image Tag

The application pod cannot start - it's stuck trying to pull an image.

## Your Mission

1. Identify why the image cannot be pulled
2. Determine the correct image specification
3. Fix the pod so it runs successfully

## Success Criteria

- The pod `escape-app` is in `Running` state
- The nginx container is serving traffic on port 80

## Getting Started

```bash
# Check the pod status
kubectl get pods -n escape-room-imagepullbackoff

# You'll see something like:
# NAME         READY   STATUS             RESTARTS   AGE
# escape-app   0/1     ImagePullBackOff   0          2m
```

## Namespace

All resources are in the `escape-room-imagepullbackoff` namespace.

Good luck, engineer. Every second counts.
