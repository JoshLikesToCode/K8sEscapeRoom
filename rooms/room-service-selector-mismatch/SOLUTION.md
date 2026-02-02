# Solution: Service Selector Mismatch

## Root Cause

The Service has a selector that doesn't match the pod's labels:

```yaml
# Service selector (WRONG)
selector:
  app: escapeapp    # Missing hyphen!

# Pod labels (CORRECT)
labels:
  app: escape-app   # Has hyphen
```

Because the selector doesn't match, Kubernetes cannot associate any pods with the Service, resulting in zero endpoints. The pod runs fine, but traffic sent to the Service has nowhere to go.

## Diagnosis Steps

```bash
# Step 1: Verify pod is running (it is!)
kubectl get pods -n escape-room-service-selector-mismatch
# Output: escape-app-xxxxx   1/1   Running   0   ...

# Step 2: Check service exists
kubectl get svc -n escape-room-service-selector-mismatch
# Output: escape-service   ClusterIP   10.x.x.x   <none>   80/TCP   ...

# Step 3: Check endpoints - THIS IS THE KEY
kubectl get endpoints escape-service -n escape-room-service-selector-mismatch
# Output: escape-service   <none>   ← NO ENDPOINTS!

# Step 4: Compare labels and selectors
kubectl get pods -n escape-room-service-selector-mismatch --show-labels
# Shows: app=escape-app

kubectl get svc escape-service -n escape-room-service-selector-mismatch -o jsonpath='{.spec.selector}'
# Shows: {"app":"escapeapp"} ← MISMATCH!
```

## The Fix

### Option 1: Patch the Service Selector

```bash
kubectl patch svc escape-service -n escape-room-service-selector-mismatch \
  --type='json' \
  -p='[{"op": "replace", "path": "/spec/selector/app", "value": "escape-app"}]'
```

### Option 2: Edit the Service Directly

```bash
kubectl edit svc escape-service -n escape-room-service-selector-mismatch
```

Change:
```yaml
selector:
  app: escapeapp
```

To:
```yaml
selector:
  app: escape-app
```

### Option 3: Replace the Service

```bash
kubectl get svc escape-service -n escape-room-service-selector-mismatch -o yaml > svc.yaml
# Edit svc.yaml to fix the selector
kubectl replace -f svc.yaml
```

## Verification

```bash
# Check endpoints now exist
kubectl get endpoints escape-service -n escape-room-service-selector-mismatch
# Should show: escape-service   10.x.x.x:80

# Test connectivity
kubectl run test-curl --rm -it --image=curlimages/curl --restart=Never -n escape-room-service-selector-mismatch -- curl -s http://escape-service
# Should return nginx welcome page HTML
```

## Lessons Learned

1. **Always check endpoints** when debugging Service connectivity issues
2. Labels and selectors must match **exactly** (case-sensitive, hyphen-sensitive)
3. A Service with no endpoints means the selector doesn't match any pods
4. Pod running ≠ Service working - they're independent

## Real-World Considerations

This commonly happens when:
- Copy-paste errors in YAML
- Refactoring label names without updating all references
- Different teams manage Deployments and Services
- Auto-generated names vs manual names don't match

Best practices:
- Use consistent labeling conventions across your team
- Use Helm/Kustomize to ensure labels are consistent
- Add `kubectl get endpoints` to your debugging checklist
- Consider using label validation in CI/CD
- Use `kubectl describe svc` which shows endpoint count
