# Escape Room: Service Selector Mismatch

The application is running but users report they cannot access it. The Service appears to be configured, but something is wrong.

## Your Mission

1. Verify the application pod is running
2. Investigate why the Service isn't routing traffic to the pod
3. Fix the networking so the application is accessible

## Success Criteria

- The pod `escape-app` remains in `Running` state
- The Service `escape-service` has at least 1 endpoint
- You can curl the service and get a response

## Getting Started

```bash
# Check the pod status - it should be Running
kubectl get pods -n escape-room-service-selector-mismatch

# Check the service
kubectl get svc -n escape-room-service-selector-mismatch

# Check the endpoints - this is the key!
kubectl get endpoints -n escape-room-service-selector-mismatch
```

## Namespace

All resources are in the `escape-room-service-selector-mismatch` namespace.

Good luck, engineer. The app is running, but nobody can reach it.
