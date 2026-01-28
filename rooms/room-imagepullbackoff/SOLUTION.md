# Solution: ImagePullBackOff - Invalid Image Tag

## Root Cause

The pod specifies an invalid image tag: `nginx:latset` (typo - should be `latest`).

This is a very common real-world issue, often caused by:
- Typos in manifests
- Copy-paste errors
- Missing or deleted image tags
- Wrong registry URLs

## Diagnosis Steps

```bash
# 1. Check pod status - see ImagePullBackOff
kubectl get pods -n escape-room-imagepullbackoff

# 2. Describe the pod to see events
kubectl describe pod escape-app -n escape-room-imagepullbackoff

# Look for events like:
# Events:
#   Type     Reason     Age   From               Message
#   ----     ------     ----  ----               -------
#   Normal   Scheduled  30s   default-scheduler  Successfully assigned...
#   Normal   Pulling    29s   kubelet            Pulling image "nginx:latset"
#   Warning  Failed     28s   kubelet            Failed to pull image "nginx:latset":
#                                                rpc error: manifest for nginx:latset not found
#   Warning  Failed     28s   kubelet            Error: ErrImagePull
#   Normal   BackOff    27s   kubelet            Back-off pulling image "nginx:latset"
#   Warning  Failed     27s   kubelet            Error: ImagePullBackOff

# 3. Verify the image specification
kubectl get pod escape-app -n escape-room-imagepullbackoff -o jsonpath='{.spec.containers[0].image}'
# Output: nginx:latset
```

## The Fix

### Option 1: Quick Fix with kubectl run

```bash
# Delete the broken pod
kubectl delete pod escape-app -n escape-room-imagepullbackoff

# Create a new pod with the correct image
kubectl run escape-app -n escape-room-imagepullbackoff \
  --image=nginx:latest \
  --port=80
```

### Option 2: Apply Corrected YAML

```bash
# Delete the broken pod
kubectl delete pod escape-app -n escape-room-imagepullbackoff

# Apply the fixed manifest
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: escape-app
  namespace: escape-room-imagepullbackoff
  labels:
    app: escape-app
    room: imagepullbackoff
spec:
  containers:
    - name: app
      image: nginx:latest
      ports:
        - containerPort: 80
      resources:
        requests:
          memory: "64Mi"
          cpu: "50m"
        limits:
          memory: "128Mi"
          cpu: "200m"
EOF
```

## Verification

```bash
# Check the pod is now running
kubectl get pods -n escape-room-imagepullbackoff
# NAME         READY   STATUS    RESTARTS   AGE
# escape-app   1/1     Running   0          30s

# Verify nginx is responding
kubectl exec escape-app -n escape-room-imagepullbackoff -- curl -s localhost:80 | head -5
# Or port-forward and test locally:
kubectl port-forward pod/escape-app 8080:80 -n escape-room-imagepullbackoff &
curl localhost:8080
```

## Lessons Learned

1. **Read the events carefully** - They tell you exactly what's wrong
2. **Check image names for typos** - Very common issue
3. **Use specific tags** - Avoid `:latest` in production; use specific versions
4. **Validate manifests before applying** - Use `kubectl apply --dry-run=client`

## Real-World Prevention

In production, prevent this issue with:

```yaml
# 1. Use specific image tags (not latest)
image: nginx:1.25.3

# 2. Use image digest for immutability
image: nginx@sha256:abc123...

# 3. Set imagePullPolicy appropriately
imagePullPolicy: IfNotPresent  # or Always for latest
```

**CI/CD best practices:**
- Validate image exists before deployment
- Use container registry webhooks
- Implement admission controllers (e.g., Kyverno, OPA) to enforce image policies
