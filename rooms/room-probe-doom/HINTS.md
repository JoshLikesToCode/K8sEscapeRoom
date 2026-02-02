# Hints: Probe Doom

---

## Hint Level 1: Where to Look

The pod keeps restarting, but not because the application is crashing - Kubernetes is actively killing it. This suggests something external to the app is deciding it's unhealthy.

Check what's happening:
```bash
kubectl describe pod escape-app -n escape-room-probe-doom
kubectl get events -n escape-room-probe-doom --sort-by='.lastTimestamp'
```

Look for messages about "unhealthy" or "killing" in the events.

---

## Hint Level 2: What to Look For

Kubernetes uses probes to check if containers are healthy:
- **Liveness probe**: Is the container alive? If it fails, container is killed and restarted.
- **Readiness probe**: Is the container ready for traffic? If it fails, pod is removed from service endpoints.

Check the pod's probe configuration:
```bash
kubectl get pod escape-app -n escape-room-probe-doom -o yaml | grep -A10 livenessProbe
kubectl get pod escape-app -n escape-room-probe-doom -o yaml | grep -A10 readinessProbe
```

What endpoint are the probes hitting? Does that endpoint exist?

---

## Hint Level 3: The Problem

The probes are configured to check `/healthz` on port 80:
```yaml
livenessProbe:
  httpGet:
    path: /healthz
    port: 80
```

But nginx doesn't have a `/healthz` endpoint by default! It returns 404, which counts as a probe failure.

Test it yourself (if the pod is momentarily up):
```bash
kubectl exec escape-app -n escape-room-probe-doom -- curl -s localhost/healthz
# Returns 404 Not Found
```

---

## Hint Level 4: How to Fix

You need to change the probe to hit an endpoint that actually exists. For nginx, the root path `/` works fine.

### Option A: Patch the pod (requires delete/recreate)
Since you can't change probes on a running pod, you need to:
1. Get the pod YAML: `kubectl get pod escape-app -n escape-room-probe-doom -o yaml > pod.yaml`
2. Edit the probe paths from `/healthz` to `/`
3. Delete and recreate: `kubectl delete pod escape-app -n escape-room-probe-doom && kubectl apply -f pod.yaml`

### Option B: Edit and replace
```bash
kubectl get pod escape-app -n escape-room-probe-doom -o yaml | \
  sed 's|/healthz|/|g' | \
  kubectl replace --force -f -
```

After fixing, the pod should stabilize with 0 new restarts.
