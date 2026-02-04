# Solution: Slow Death

## Root Causes (MULTIPLE)

This incident has **two resource-related failures** that cause different symptoms:

### Failure #1: Memory Limit Too Low

```yaml
resources:
  limits:
    memory: "24Mi"   # nginx needs ~50-60Mi minimum
```

Result: Container gets `OOMKilled` when it exceeds 24Mi, which happens quickly.

### Failure #2: Liveness Probe Too Aggressive

```yaml
livenessProbe:
  timeoutSeconds: 1      # Too short
  failureThreshold: 1    # One failure = death
  periodSeconds: 2       # Checks too frequently
```

Result: Any momentary slowdown (GC pause, load spike, slow startup) causes Kubernetes to kill the pod.

**Why this is tricky:**
- Both issues cause restarts, but for different reasons
- Logs/events show different failure modes at different times
- Fixing just memory still leaves aggressive probes
- Fixing just probes still leaves OOM kills
- The pattern seems "random" but isn't

## Diagnosis Steps

```bash
# Step 1: Notice high restart count
kubectl get pods -n escape-boss-slow-death
# NAME         READY   STATUS             RESTARTS     AGE
# escape-app   0/1     CrashLoopBackOff   5 (2m ago)   5m

# Step 2: Check termination reason (varies!)
kubectl get pod escape-app -n escape-boss-slow-death \
  -o jsonpath='{.status.containerStatuses[0].lastState.terminated.reason}'
# Sometimes: OOMKilled
# Sometimes: Error (from probe-induced kill)

# Step 3: Check events - see BOTH failure types
kubectl get events -n escape-boss-slow-death --sort-by='.lastTimestamp'
# Warning  Unhealthy   Liveness probe failed...
# Warning  OOMKilling  Memory limit exceeded...

# Step 4: Check resource limits
kubectl get pod escape-app -n escape-boss-slow-death \
  -o jsonpath='{.spec.containers[0].resources.limits}'
# {"cpu":"50m","memory":"24Mi"}  <- 24Mi is too low!

# Step 5: Check probe configuration
kubectl get pod escape-app -n escape-boss-slow-death \
  -o jsonpath='{.spec.containers[0].livenessProbe}'
# failureThreshold:1, periodSeconds:2, timeoutSeconds:1  <- Too aggressive!
```

## The Fixes

Since pod specs are immutable, you need to delete and recreate with fixes.

### Create Fixed Manifest

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
        memory: "64Mi"
        cpu: "10m"
      limits:
        memory: "128Mi"   # FIX #1: Adequate memory
        cpu: "100m"
    livenessProbe:
      httpGet:
        path: /
        port: 80
      initialDelaySeconds: 5
      periodSeconds: 10
      timeoutSeconds: 5      # FIX #2: Reasonable timeout
      failureThreshold: 3    # FIX #2: Allow retries
```

### Apply the Fix

```bash
# Save the fixed manifest
cat > /tmp/fixed-pod.yaml << 'EOF'
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
        memory: "64Mi"
        cpu: "10m"
      limits:
        memory: "128Mi"
        cpu: "100m"
    livenessProbe:
      httpGet:
        path: /
        port: 80
      initialDelaySeconds: 5
      periodSeconds: 10
      timeoutSeconds: 5
      failureThreshold: 3
EOF

# Delete and recreate
kubectl delete pod escape-app -n escape-boss-slow-death
kubectl apply -f /tmp/fixed-pod.yaml
```

## Verification

```bash
# Watch for stability
kubectl get pods -n escape-boss-slow-death -w

# After 30+ seconds, verify no new restarts
kubectl get pods -n escape-boss-slow-death
# NAME         READY   STATUS    RESTARTS   AGE
# escape-app   1/1     Running   0          1m

# Check no OOM events
kubectl get events -n escape-boss-slow-death | grep -i oom
# (should be empty or only old events)
```

## Lessons Learned

1. **Multiple failures can have different symptoms** - making debugging confusing
2. **OOMKilled and probe failures look different** but can happen to the same pod
3. **Test with production-like resource limits** before deploying
4. **Liveness probes should be lenient** - failureThreshold >= 3, reasonable timeouts
5. **"Works locally" doesn't mean "works in k8s"** - local Docker often has no limits

## Real-World Considerations

This pattern occurs when:
- Resource limits copied from "starter templates" without adjustment
- Probe configurations not tuned for the specific application
- Development testing doesn't include resource constraints
- Auto-scaling or load causes memory spikes

Prevention:
- Load test with realistic memory limits
- Set `failureThreshold` >= 3 for liveness probes
- Use appropriate `initialDelaySeconds` for slow-starting apps
- Monitor memory usage and adjust limits accordingly
- Consider using VPA (Vertical Pod Autoscaler) for recommendations
