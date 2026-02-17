# Solution: Probe Doom

## Root Cause

The deployment has liveness and readiness probes configured to check port 8080:

```yaml
livenessProbe:
  httpGet:
    path: /
    port: 8080   # Nothing is listening here!
```

The nginx container listens on port 80, not 8080. Since nothing is listening on port 8080, every probe attempt gets "connection refused," which Kubernetes counts as a failure. After the configured `failureThreshold` (2 failures), Kubernetes kills the container.

With `periodSeconds: 3` and `failureThreshold: 2`, the container gets killed every ~6 seconds, causing CrashLoopBackOff.

## Diagnosis Steps

```bash
# Step 1: Notice the restart count climbing
kubectl get pods -n escape-room-probe-doom -w
# Output: escape-app-xxx-xxx   0/1   Running   4 (2s ago)   30s

# Step 2: Check events for the cause
kubectl get events -n escape-room-probe-doom --sort-by='.lastTimestamp'
# You'll see:
# Warning  Unhealthy  Liveness probe failed: Get "http://...:8080/":
#                      dial tcp ...:8080: connect: connection refused
# Normal   Killing    Container app failed liveness probe, will be restarted

# Step 3: Compare probe port vs container port
kubectl get deployment escape-app -n escape-room-probe-doom \
  -o jsonpath='{.spec.template.spec.containers[0].ports[0].containerPort}'
# Output: 80

kubectl get deployment escape-app -n escape-room-probe-doom \
  -o jsonpath='{.spec.template.spec.containers[0].livenessProbe.httpGet.port}'
# Output: 8080  ← MISMATCH!
```

## The Fix

Edit the deployment to change the probe ports from 8080 to 80:

```bash
kubectl edit deployment escape-app -n escape-room-probe-doom
```

Find both probe sections and change the port:

```yaml
# Before (WRONG):
livenessProbe:
  httpGet:
    path: /
    port: 8080    # connection refused - nothing listening

# After (FIXED):
livenessProbe:
  httpGet:
    path: /
    port: 80      # matches containerPort
```

Do the same for the `readinessProbe` section. Save and exit — Kubernetes will automatically roll out a new pod with the corrected probes.

## Verification

```bash
# Watch the new pod roll out
kubectl get pods -n escape-room-probe-doom -w
# Old pod terminates, new pod starts with 0 restarts

# After ~30 seconds, verify stability
kubectl get pods -n escape-room-probe-doom
# Should show: escape-app-xxx-xxx   1/1   Running   0   30s

# Confirm the probes are passing
kubectl describe pod -l app=escape-app -n escape-room-probe-doom | grep -A5 "Liveness:"
```

## Lessons Learned

1. **"Connection refused" means wrong port** - nothing is listening there. This is different from a 404 (wrong path) or timeout (port blocked/slow app).
2. **Probe port must match the container port** - not the Service port or any other port
3. **Liveness probe failures cause container restarts** - they're the "kill switch"
4. **CrashLoopBackOff isn't always an app crash** - it can be probe-induced kills
5. Check events for "Unhealthy" and "Killing" messages when debugging restarts

## Real-World Considerations

This commonly happens when:
- Copying probe configs from one app to another without adjusting ports
- Confusing Service port (what clients connect to) with container port (what the app listens on)
- Adding sidecars that remap ports
- Helm templates using the wrong port variable (`service.port` vs `container.port`)
- Framework defaults differ from deployment config (e.g., Spring Boot defaults to 8080)

Best practices:
- Always verify probe port matches `containerPort` in the pod spec
- Use named ports for clarity: `port: http` instead of `port: 80`
- Test probes manually with `kubectl exec ... curl` before deploying
- Use `startupProbe` for apps with variable startup times
- Consider `tcpSocket` probes if HTTP isn't practical
