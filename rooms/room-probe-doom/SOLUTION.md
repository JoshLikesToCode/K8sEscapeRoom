# Solution: Probe Doom

## Root Cause

The pod has liveness and readiness probes configured to check `/healthz`:

```yaml
livenessProbe:
  httpGet:
    path: /healthz   # This endpoint doesn't exist!
    port: 80
```

The nginx container doesn't have a `/healthz` endpoint, so it returns HTTP 404. Kubernetes interprets any non-2xx response as a probe failure. After the configured `failureThreshold` (2 failures), Kubernetes kills the container.

With `periodSeconds: 3` and `failureThreshold: 2`, the container gets killed every ~6 seconds, causing CrashLoopBackOff.

## Diagnosis Steps

```bash
# Step 1: Notice the restart count climbing
kubectl get pods -n escape-room-probe-doom -w
# Output: escape-app   0/1   Running   4 (2s ago)   30s

# Step 2: Check events for the cause
kubectl get events -n escape-room-probe-doom --sort-by='.lastTimestamp'
# You'll see:
# Warning  Unhealthy  Liveness probe failed: HTTP probe failed with statuscode: 404
# Normal   Killing    Container app failed liveness probe, will be restarted

# Step 3: Check the probe configuration
kubectl get pod escape-app -n escape-room-probe-doom -o jsonpath='{.spec.containers[0].livenessProbe}' | jq
# Shows the probe hitting /healthz

# Step 4: Verify /healthz doesn't exist (when pod is momentarily up)
kubectl exec escape-app -n escape-room-probe-doom -- curl -s -o /dev/null -w "%{http_code}" localhost/healthz
# Returns: 404
```

## The Fix

### Option 1: Replace Pod with Fixed Probes

```bash
# Export current pod
kubectl get pod escape-app -n escape-room-probe-doom -o yaml > pod.yaml

# Edit pod.yaml - change /healthz to / in both probes
# Or use sed:
sed -i 's|/healthz|/|g' pod.yaml

# Replace the pod
kubectl delete pod escape-app -n escape-room-probe-doom
kubectl apply -f pod.yaml -n escape-room-probe-doom
```

### Option 2: One-liner Replace

```bash
kubectl get pod escape-app -n escape-room-probe-doom -o yaml | \
  sed 's|path: /healthz|path: /|g' | \
  kubectl replace --force -f -
```

### Option 3: Remove Probes Entirely (Not Recommended for Production)

```bash
kubectl get pod escape-app -n escape-room-probe-doom -o yaml | \
  grep -v -A6 "livenessProbe:" | \
  grep -v -A6 "readinessProbe:" | \
  kubectl replace --force -f -
```

## Verification

```bash
# Watch the pod stabilize
kubectl get pods -n escape-room-probe-doom -w
# Restart count should stop increasing

# After ~30 seconds, verify stability
kubectl get pods -n escape-room-probe-doom
# Should show: escape-app   1/1   Running   0   30s  (or low stable restart count)

# Check the probe is now passing
kubectl describe pod escape-app -n escape-room-probe-doom | grep -A5 "Liveness:"
```

## Lessons Learned

1. **Liveness probe failures cause container restarts** - they're the "kill switch"
2. **Always verify probe endpoints exist** before configuring probes
3. **404 is a probe failure** - only 2xx responses count as success
4. **CrashLoopBackOff isn't always an app crash** - it can be probe-induced kills
5. Check events for "Unhealthy" and "Killing" messages when debugging restarts

## Real-World Considerations

This commonly happens when:
- Copying probe configs from one app to another without adjusting paths
- Application doesn't implement the expected health endpoint
- Health endpoint exists but on a different port
- Probe timeouts are too short for slow-starting apps

Best practices:
- Implement a proper `/health` or `/healthz` endpoint in your applications
- Use appropriate `initialDelaySeconds` for slow-starting apps
- Set reasonable `timeoutSeconds` for your environment
- Consider using `tcpSocket` probes if HTTP isn't practical
- Test probes manually with `kubectl exec ... curl` before deploying
- Use `startupProbe` for apps with variable startup times
