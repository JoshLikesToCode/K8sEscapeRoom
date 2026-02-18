# Hints: Probe Doom

---

## Hint Level 1: Where to Look

The pod keeps restarting, but not because the application is crashing - Kubernetes is actively killing it. This suggests something external to the app is deciding it's unhealthy.

Check what's happening:
```bash
kubectl describe pod <pod-name> -n escape-room-health-inspector
kubectl get events -n escape-room-health-inspector --sort-by='.lastTimestamp'
```

Look for messages about "unhealthy" or "killing" in the events.

---

## Hint Level 2: What to Look For

Kubernetes uses probes to check if containers are healthy:
- **Liveness probe**: Is the container alive? If it fails, the container is killed and restarted.
- **Readiness probe**: Is the container ready for traffic? If it fails, the pod is removed from service endpoints.

The events should show something like:
```
Liveness probe failed: Get "http://...:8080/": dial tcp ...:8080: connect: connection refused
```

"Connection refused" means nothing is listening on that port. Is the probe checking the right port?

---

## Hint Level 3: The Problem

Look at the deployment spec — compare `containerPort` with the probe `port`:

```bash
kubectl get deployment escape-app -n escape-room-health-inspector -o yaml
```

You'll see the mismatch:
```yaml
ports:
  - containerPort: 80       # app listens on 80
...
livenessProbe:
  httpGet:
    path: /
    port: 8080              # probe checks 8080 — nothing there!
```

The probe is checking a port that nothing is listening on.

---

## Hint Level 4: How to Fix

Edit the deployment to fix the probe ports. Since this is a Deployment, Kubernetes will automatically roll out a new pod with the corrected config:

```bash
kubectl edit deployment escape-app -n escape-room-health-inspector
# Change port: 8080 to port: 80 in both the liveness and readiness probes, then save
```
