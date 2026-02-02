# Solution: Secret Missing

## Root Cause

The pod specification includes an environment variable that references a Secret:

```yaml
env:
  - name: DATABASE_PASSWORD
    valueFrom:
      secretKeyRef:
        name: db-credentials
        key: password
```

This Secret was never created, so Kubernetes cannot start the container. The `CreateContainerConfigError` status indicates that the container runtime couldn't configure the container environment because a required Secret is missing.

## Diagnosis Steps

```bash
# Step 1: Check pod status
kubectl get pods -n escape-room-secret-missing
# Output: escape-app   0/1   CreateContainerConfigError   0   ...

# Step 2: Check events for details
kubectl describe pod escape-app -n escape-room-secret-missing
# Look at Events section - you'll see:
# Warning  Failed  ...  secret "db-credentials" not found

# Step 3: Verify Secret doesn't exist
kubectl get secrets -n escape-room-secret-missing
# Output: No resources found (or only default service account token)

# Step 4: Check what the pod expects
kubectl get pod escape-app -n escape-room-secret-missing -o yaml | grep -A5 secretKeyRef
```

## The Fix

### Option 1: Create Secret Imperatively

```bash
kubectl create secret generic db-credentials \
  --from-literal=password=supersecretpassword123 \
  -n escape-room-secret-missing
```

### Option 2: Create Secret Declaratively

Create a file `secret.yaml`:
```yaml
apiVersion: v1
kind: Secret
metadata:
  name: db-credentials
  namespace: escape-room-secret-missing
type: Opaque
stringData:
  password: supersecretpassword123
```

Apply it:
```bash
kubectl apply -f secret.yaml
```

Note: Using `stringData` allows plain text; using `data` requires base64 encoding.

## Verification

```bash
# Check the Secret was created
kubectl get secret db-credentials -n escape-room-secret-missing

# Watch the pod recover
kubectl get pods -n escape-room-secret-missing -w

# Check the logs once running
kubectl logs escape-app -n escape-room-secret-missing
# Should show: "Application started successfully!"
```

## Lessons Learned

1. **CreateContainerConfigError** often means a Secret or ConfigMap reference is broken
2. Secrets must exist before pods that reference them can start
3. The `secretKeyRef` must match both the Secret name AND the key within the Secret
4. Secrets are namespace-scoped - they must be in the same namespace as the pod

## Real-World Considerations

This commonly happens when:
- Deploying to a new environment without creating secrets first
- Secret was deleted or expired
- Typo in secret name or key (both are case-sensitive!)
- Secret exists but in wrong namespace
- CI/CD pipeline didn't provision secrets before deployment

Best practices:
- Use external secret management (Vault, AWS Secrets Manager, etc.)
- Use tools like External Secrets Operator to sync secrets
- Consider `optional: true` on secretKeyRef only if truly optional
- Never commit secrets to git - use sealed secrets or external references
- Document required secrets in deployment documentation
