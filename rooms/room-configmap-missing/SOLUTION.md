# Solution: ConfigMap Missing

## Root Cause

The pod specification includes an `envFrom` block that references a ConfigMap named `app-config`:

```yaml
envFrom:
  - configMapRef:
      name: app-config
```

This ConfigMap was never created, so Kubernetes cannot start the container. The `CreateContainerConfigError` status indicates that the container runtime couldn't configure the container environment because a required resource is missing.

## Diagnosis Steps

```bash
# Step 1: Check pod status
kubectl get pods -n escape-room-configmap-missing
# Output: escape-app   0/1   CreateContainerConfigError   0   ...

# Step 2: Check events for details
kubectl describe pod escape-app -n escape-room-configmap-missing
# Look at Events section - you'll see:
# Warning  Failed  ...  configmap "app-config" not found

# Step 3: Verify ConfigMap doesn't exist
kubectl get configmaps -n escape-room-configmap-missing
# Output: No resources found

# Step 4: Check what the pod expects
kubectl get pod escape-app -n escape-room-configmap-missing -o yaml | grep -A5 envFrom
```

## The Fix

### Option 1: Create ConfigMap Imperatively

```bash
kubectl create configmap app-config \
  --from-literal=APP_NAME=escape-app \
  --from-literal=APP_ENV=production \
  --from-literal=LOG_LEVEL=info \
  -n escape-room-configmap-missing
```

### Option 2: Create ConfigMap Declaratively

Create a file `configmap.yaml`:
```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: app-config
  namespace: escape-room-configmap-missing
data:
  APP_NAME: escape-app
  APP_ENV: production
  LOG_LEVEL: info
```

Apply it:
```bash
kubectl apply -f configmap.yaml
```

## Verification

```bash
# Check the ConfigMap was created
kubectl get configmap app-config -n escape-room-configmap-missing

# Watch the pod recover
kubectl get pods -n escape-room-configmap-missing -w

# Check the logs once running
kubectl logs escape-app -n escape-room-configmap-missing
# Should show: "Application configured successfully!"
```

## Lessons Learned

1. **CreateContainerConfigError** usually means a ConfigMap or Secret reference is broken
2. Always check `kubectl describe pod` events for the specific error message
3. Pods referencing ConfigMaps/Secrets will fail to start if those resources don't exist
4. ConfigMaps must be created in the same namespace as the pod that uses them

## Real-World Considerations

This commonly happens when:
- Deploying to a new namespace without the required ConfigMaps
- ConfigMap was accidentally deleted
- Typo in the ConfigMap name (case-sensitive!)
- GitOps pipeline applied Pod before ConfigMap (ordering issue)

Best practices:
- Use Helm or Kustomize to ensure ConfigMaps are created with deployments
- Consider using `optional: true` on configMapRef if the config is truly optional
- Validate manifests reference existing resources before deployment
