# Solution: CrashLoopBackOff - Missing Environment Variable

## Root Cause

The pod is missing a required environment variable `DATABASE_URL`. The application checks for this variable at startup and exits with an error if it's not present.

## Diagnosis Steps

```bash
# 1. Check pod status - see CrashLoopBackOff
kubectl get pods -n escape-room-crashloop-env

# 2. Check logs to see the actual error
kubectl logs escape-app -n escape-room-crashloop-env
# Output: FATAL: Required environment variable DATABASE_URL is not set

# 3. Inspect the pod spec to confirm missing env var
kubectl get pod escape-app -n escape-room-crashloop-env -o yaml | grep -A 10 "env:"
# (No env section present)
```

## The Fix

Since you cannot modify environment variables on a running pod, you need to delete and recreate it.

### Option 1: Quick Fix with kubectl run (Recommended for Learning)

```bash
# Delete the broken pod
kubectl delete pod escape-app -n escape-room-crashloop-env

# Create a new pod with the environment variable
kubectl run escape-app -n escape-room-crashloop-env \
  --image=busybox:1.36 \
  --restart=Never \
  --env="DATABASE_URL=postgres://localhost:5432/mydb" \
  --command -- /bin/sh -c '
    if [ -z "$DATABASE_URL" ]; then
      echo "FATAL: Required environment variable DATABASE_URL is not set"
      exit 1
    fi
    echo "Connected to database: $DATABASE_URL"
    echo "Application started successfully"
    while true; do sleep 3600; done
  '
```

### Option 2: YAML Patch (More Realistic)

```bash
# Create a fixed version of the pod
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: escape-app
  namespace: escape-room-crashloop-env
  labels:
    app: escape-app
    room: crashloop-env
spec:
  containers:
    - name: app
      image: busybox:1.36
      command:
        - /bin/sh
        - -c
        - |
          if [ -z "\$DATABASE_URL" ]; then
            echo "FATAL: Required environment variable DATABASE_URL is not set"
            exit 1
          fi
          echo "Connected to database: \$DATABASE_URL"
          echo "Application started successfully"
          while true; do sleep 3600; done
      env:
        - name: DATABASE_URL
          value: "postgres://localhost:5432/mydb"
      resources:
        requests:
          memory: "32Mi"
          cpu: "10m"
        limits:
          memory: "64Mi"
          cpu: "100m"
EOF
```

**Note:** You may need to delete the existing pod first:
```bash
kubectl delete pod escape-app -n escape-room-crashloop-env
```

## Verification

```bash
# Check the pod is now running
kubectl get pods -n escape-room-crashloop-env
# NAME         READY   STATUS    RESTARTS   AGE
# escape-app   1/1     Running   0          30s

# Verify the logs show success
kubectl logs escape-app -n escape-room-crashloop-env
# Connected to database: postgres://localhost:5432/mydb
# Application started successfully
```

## Lessons Learned

1. **Always check logs first** - CrashLoopBackOff usually has a clear error message
2. **Environment variables matter** - Many real applications fail without required config
3. **Pods are immutable** - You can't change env vars without recreating the pod
4. **In production, use Deployments** - They make updates easier and provide rollback

## Real-World Considerations

In production, you would:
- Use a **Deployment** instead of a bare Pod (allows rolling updates)
- Store secrets in **Kubernetes Secrets** (not plain text in manifests)
- Use **ConfigMaps** for non-sensitive configuration
- Set up **health checks** (readiness/liveness probes)

```yaml
# Example: Using a Secret for DATABASE_URL
env:
  - name: DATABASE_URL
    valueFrom:
      secretKeyRef:
        name: app-secrets
        key: database-url
```
