# Escape Room: Out of Service

The application is running fine but traffic never reaches it. Everything appears to be configured, but something isn't connecting.

## Your Mission

1. Verify the application pod is running
2. Investigate why traffic isn't reaching the pod
3. Fix the networking so the application is accessible

## Success Criteria

- The pod `escape-app` remains in `Running` state
- The Service `escape-service` has at least 1 endpoint
- You can curl the service and get a response

## Getting Started

```bash
# Check the pod status - it should be Running
kubectl get pods -n escape-room-out-of-service

# Check the service
kubectl get svc -n escape-room-out-of-service

# Check the endpoints - this is the key!
kubectl get endpoints -n escape-room-out-of-service
```

## Namespace

All resources are in the `escape-room-out-of-service` namespace.

Good luck, engineer. The app is running, but nobody can reach it.
