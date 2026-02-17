# Solution: Checkout Meltdown

## Root Causes (MULTIPLE)

This incident has **two independent failures** that must both be fixed:

### Failure #1: Service Selector Mismatch

```yaml
# Service selector (WRONG):
selector:
  app: checkout      # Looking for "checkout"

# Pod labels (ACTUAL):
labels:
  app: checkout-api  # Pods have "checkout-api"
```

Result: Service has 0 endpoints, all traffic returns 503.

### Failure #2: Readiness Probe Misconfigured

```yaml
readinessProbe:
  httpGet:
    path: /
    port: 8080       # nginx listens on 80, not 8080
```

Result: Pods are Running but never become Ready (0/1).

**Why this is tricky:** Fixing EITHER problem alone doesn't restore service:
- Fix selector only → endpoints still empty (pods not ready)
- Fix probe only → endpoints still empty (selector wrong)

## Diagnosis Steps

```bash
# Step 1: Check pod status - notice 0/1 Ready
kubectl get pods -n escape-boss-checkout-meltdown
# NAME                            READY   STATUS    RESTARTS   AGE
# checkout-api-xxxxx              0/1     Running   0          5m
# checkout-api-yyyyy              0/1     Running   0          5m

# Step 2: Check endpoints - notice <none>
kubectl get endpoints checkout-service -n escape-boss-checkout-meltdown
# NAME               ENDPOINTS   AGE
# checkout-service   <none>      5m

# Step 3: Compare selector vs labels
kubectl get svc checkout-service -n escape-boss-checkout-meltdown -o jsonpath='{.spec.selector}'
# {"app":"checkout"}

kubectl get pods -n escape-boss-checkout-meltdown --show-labels
# app=checkout-api  ← MISMATCH!

# Step 4: Check probe configuration
kubectl get deployment checkout-api -n escape-boss-checkout-meltdown -o jsonpath='{.spec.template.spec.containers[0].readinessProbe}'
# port: 8080  ← WRONG! nginx listens on 80

# Step 5: Check events for probe failures
kubectl get events -n escape-boss-checkout-meltdown --sort-by='.lastTimestamp' | grep -i readiness
# Warning  Unhealthy  Readiness probe failed: dial tcp ...:8080: connect: connection refused
```

## The Fixes

### Fix #1: Correct Service Selector

Edit the service to fix the selector:
```bash
kubectl edit svc checkout-service -n escape-boss-checkout-meltdown
# Change: app: checkout
# To:     app: checkout-api
```

Alternative — use a JSON patch to make the change non-interactively. This is useful in scripts or CI/CD pipelines where `kubectl edit` isn't practical:
```bash
kubectl patch svc checkout-service -n escape-boss-checkout-meltdown \
  --type='json' \
  -p='[{"op": "replace", "path": "/spec/selector/app", "value": "checkout-api"}]'
```

### Fix #2: Correct Readiness Probe

Edit the deployment to fix the probe port:
```bash
kubectl edit deployment checkout-api -n escape-boss-checkout-meltdown
# Change readinessProbe port from 8080 to 80
```

Alternative — use a JSON patch for non-interactive environments (scripts, CI/CD):
```bash
kubectl patch deployment checkout-api -n escape-boss-checkout-meltdown \
  --type='json' \
  -p='[{"op": "replace", "path": "/spec/template/spec/containers/0/readinessProbe/httpGet/port", "value": 80}]'
```

## Verification

```bash
# Wait for new pods to roll out
kubectl rollout status deployment/checkout-api -n escape-boss-checkout-meltdown

# Check pods are now 1/1 Ready
kubectl get pods -n escape-boss-checkout-meltdown
# NAME                            READY   STATUS    RESTARTS   AGE
# checkout-api-xxxxx              1/1     Running   0          30s

# Check endpoints exist
kubectl get endpoints checkout-service -n escape-boss-checkout-meltdown
# NAME               ENDPOINTS           AGE
# checkout-service   10.x.x.x:80,...     5m

# Test the service
kubectl run test --rm -it --image=curlimages/curl --restart=Never \
  -n escape-boss-checkout-meltdown -- curl -s http://checkout-service
# Should return nginx welcome page
```

## Lessons Learned

1. **Multiple failures can mask each other** - pods not ready means selector fix won't help
2. **Check both labels AND readiness** when debugging service connectivity
3. **Running ≠ Ready** - a pod can be Running but not receiving traffic
4. **Always verify endpoints** as part of service debugging
5. **Read the full probe config** - the port must match what the container actually listens on

## Real-World Considerations

This pattern often occurs when:
- Different engineers set up Deployment and Service separately
- Copy-paste from different environments with different naming
- Probe configuration copied from another app without adjustment
- Rushed deployments skip validation steps

Prevention:
- Use Helm charts or Kustomize for consistent naming
- Include health endpoints in all applications
- Add pre-deploy validation for selector/label matching
- Use admission controllers to validate probe configurations
