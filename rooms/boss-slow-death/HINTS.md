# Hints: Slow Death

**Warning:** This is a boss room with MULTIPLE failures. The pod is dying from different causes at different times.

---

## Hint Level 1: Where to Look

The pod is restarting repeatedly, but the causes vary. You need to investigate:

1. **Resource limits** - is the container getting enough memory?
2. **Liveness probe configuration** - is Kubernetes being too aggressive?

Check the termination history:
```bash
kubectl describe pod escape-app -n escape-boss-slow-death | grep -A5 "Last State:"
kubectl get events -n escape-boss-slow-death --sort-by='.lastTimestamp'
```

Look for BOTH `OOMKilled` and `Liveness probe failed` messages.

---

## Hint Level 2: Problem #1 - Memory Limits

Check the memory configuration:
```bash
kubectl get pod escape-app -n escape-boss-slow-death -o jsonpath='{.spec.containers[0].resources.limits.memory}'
```

nginx typically needs at least 50-64Mi to run comfortably. What's the current limit?

If you see `OOMKilled` in the termination reason, the memory limit is too low.

---

## Hint Level 3: Problem #2 - Aggressive Liveness Probe

Check the liveness probe settings:
```bash
kubectl get pod escape-app -n escape-boss-slow-death -o jsonpath='{.spec.containers[0].livenessProbe}' | jq
```

Look at these values:
- `timeoutSeconds: 1` - very short, any slow response = failure
- `failureThreshold: 1` - ONE failure = pod killed
- `periodSeconds: 2` - checking every 2 seconds

This is extremely aggressive. Any momentary hiccup kills the pod.

---

## Hint Level 4: The Fixes

You need to fix BOTH issues. Since you can't modify a running pod's resources, you need to delete and recreate.

**Create a fixed pod manifest:**

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: escape-app
  namespace: escape-boss-slow-death
  labels:
    app: escape-app
spec:
  containers:
  - name: app
    image: nginx:1.25-alpine
    ports:
    - containerPort: 80
    resources:
      requests:
        memory: "64Mi"    # Increased from 16Mi
        cpu: "10m"
      limits:
        memory: "128Mi"   # FIX #1: Increased from 24Mi
        cpu: "100m"
    livenessProbe:
      httpGet:
        path: /
        port: 80
      initialDelaySeconds: 5    # Give more startup time
      periodSeconds: 10         # Check less frequently
      timeoutSeconds: 5         # FIX #2: More lenient timeout
      failureThreshold: 3       # FIX #2: Allow some failures
```

Apply the fix:
```bash
kubectl delete pod escape-app -n escape-boss-slow-death
kubectl apply -f fixed-pod.yaml
```
