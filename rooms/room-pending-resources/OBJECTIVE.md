# Escape Room: Pending - Resource Requests Exceed Capacity

The application pod is stuck in `Pending` state and will not start.

## Your Mission

1. Identify why the pod cannot be scheduled
2. Understand the resource constraints
3. Fix the pod so it can be scheduled and run

## Success Criteria

- The pod `escape-app` is in `Running` state
- The nginx container is serving traffic on port 80

## Getting Started

```bash
# Check the pod status
kubectl get pods -n escape-room-pending-resources

# You'll see something like:
# NAME         READY   STATUS    RESTARTS   AGE
# escape-app   0/1     Pending   0          2m
```

Notice that READY is 0/1 and STATUS is Pending - the pod hasn't even started!

## Namespace

All resources are in the `escape-room-pending-resources` namespace.

Good luck, engineer. The scheduler awaits your fix.
