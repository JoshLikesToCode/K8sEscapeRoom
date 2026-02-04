# Solution: Registry Curse

## Root Causes (MULTIPLE)

This incident has **two issues** that interact:

### Issue #1: ServiceAccount References Wrong Secret

```yaml
# Secret that exists:
metadata:
  name: registry-credentials    # <-- Actual name

# ServiceAccount references:
imagePullSecrets:
  - name: registry-creds        # <-- WRONG! Missing "-entials"
```

Result: The pod can't use the registry credentials because the reference is broken.

### Issue #2: Non-Existent Registry

```yaml
image: private-registry.internal.example.com/mycompany/app:v2.1.0
```

This registry doesn't exist in the test environment. Even with correct credentials, the pull would fail.

**Why this is tricky:**
- The secret exists (red herring - leads people to think credentials are wrong)
- Recreating the secret doesn't help (the reference is the problem)
- Multiple failures mask each other

## Diagnosis Steps

```bash
# Step 1: Confirm ImagePullBackOff
kubectl get pods -n escape-boss-registry-curse
# NAME         READY   STATUS             RESTARTS   AGE
# escape-app   0/1     ImagePullBackOff   0          5m

# Step 2: Check events for the error
kubectl describe pod escape-app -n escape-boss-registry-curse
# Events:
#   Warning  Failed   Failed to pull image "private-registry.internal...":
#            rpc error: ... server misbehaving

# Step 3: Verify secret exists
kubectl get secrets -n escape-boss-registry-curse
# NAME                   TYPE                             DATA   AGE
# registry-credentials   kubernetes.io/dockerconfigjson   1      5m

# Step 4: Check ServiceAccount configuration - HERE'S THE BUG
kubectl get sa app-sa -n escape-boss-registry-curse -o yaml
# imagePullSecrets:
# - name: registry-creds    <-- WRONG NAME!

# Step 5: Verify the pod is using this ServiceAccount
kubectl get pod escape-app -n escape-boss-registry-curse -o jsonpath='{.spec.serviceAccountName}'
# app-sa
```

## The Fixes

### Fix #1: Correct the ServiceAccount Reference

```bash
kubectl patch sa app-sa -n escape-boss-registry-curse \
  --type='json' \
  -p='[{"op": "replace", "path": "/imagePullSecrets/0/name", "value": "registry-credentials"}]'
```

### Fix #2: Use a Working Image

Since the private registry doesn't exist in this environment, recreate the pod with a public image:

```bash
# Delete the failing pod
kubectl delete pod escape-app -n escape-boss-registry-curse

# Create a new pod with a working image
kubectl run escape-app -n escape-boss-registry-curse \
  --image=nginx:1.25-alpine \
  --overrides='{"spec":{"serviceAccountName":"app-sa"}}' \
  --labels="app=escape-app"
```

Or edit and reapply:
```bash
kubectl get pod escape-app -n escape-boss-registry-curse -o yaml > pod.yaml
# Edit: change image to nginx:1.25-alpine
sed -i 's|private-registry.internal.example.com/mycompany/app:v2.1.0|nginx:1.25-alpine|' pod.yaml
kubectl delete pod escape-app -n escape-boss-registry-curse
kubectl apply -f pod.yaml
```

## Verification

```bash
# Verify ServiceAccount now references correct secret
kubectl get sa app-sa -n escape-boss-registry-curse -o jsonpath='{.imagePullSecrets[*].name}'
# registry-credentials

# Check pod is now running
kubectl get pods -n escape-boss-registry-curse
# NAME         READY   STATUS    RESTARTS   AGE
# escape-app   1/1     Running   0          30s
```

## Lessons Learned

1. **Secret reference names must match exactly** - typos break the chain
2. **Check the FULL chain**: Pod → ServiceAccount → imagePullSecrets → Secret
3. **Existing resources can be red herrings** - the secret exists but isn't used
4. **Multiple failures compound** - wrong reference + wrong registry
5. **Use `kubectl get sa -o yaml`** to see imagePullSecrets configuration

## Real-World Considerations

This pattern occurs when:
- Secrets are created with slightly different names than expected
- Copy-paste errors in ServiceAccount configurations
- Different naming conventions between teams (creds vs credentials)
- Registry URLs change between environments

Prevention:
- Use consistent naming conventions
- Validate imagePullSecrets references in CI
- Use Helm charts with templated secret names
- Test image pulls in staging before production
- Document exact secret names in runbooks
