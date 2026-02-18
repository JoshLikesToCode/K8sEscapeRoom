# Solution: CrashLoopBackOff - Missing Environment Variable

## Root Cause

The deployment's pod template is missing a required environment variable `DATABASE_URL`. The application checks for this variable at startup and exits with an error if it's not present.

## Diagnosis Steps

```bash
# 1. Check pod status - see CrashLoopBackOff
kubectl get pods -n escape-room-groundhog-deploy

# 2. Check logs to see the actual error
kubectl logs -l app=escape-app -n escape-room-groundhog-deploy
# Output: FATAL: Required environment variable DATABASE_URL is not set

# 3. Inspect the deployment spec to confirm missing env var
kubectl get deployment escape-app -n escape-room-groundhog-deploy -o yaml | grep -A 10 "env:"
# (No env section present)
```

## The Fix

### Option 1: Quick Fix with kubectl set env (Recommended)

```bash
kubectl set env deployment/escape-app DATABASE_URL=postgres://localhost:5432/mydb -n escape-room-groundhog-deploy
```

This adds the environment variable and triggers a rolling update automatically.

### Option 2: Edit the Deployment Directly

```bash
kubectl edit deployment/escape-app -n escape-room-groundhog-deploy
```

Add the `env` section under the container spec:

```yaml
      containers:
        - name: app
          # ... existing fields ...
          env:
            - name: DATABASE_URL
              value: "postgres://localhost:5432/mydb"
```

Save and exit — Kubernetes will automatically roll out the change.

## Verification

```bash
# Wait for the rollout to complete
kubectl rollout status deployment/escape-app -n escape-room-groundhog-deploy

# Check the pod is now running
kubectl get pods -n escape-room-groundhog-deploy
# NAME                          READY   STATUS    RESTARTS   AGE
# escape-app-5d4f7b8c9-x2k7p   1/1     Running   0          30s

# Verify the logs show success
kubectl logs -l app=escape-app -n escape-room-groundhog-deploy
# Connected to database: postgres://localhost:5432/mydb
# Application started successfully
```

## Lessons Learned

1. **Always check logs first** - CrashLoopBackOff usually has a clear error message
2. **Environment variables matter** - Many real applications fail without required config
3. **Deployments make updates easy** - `kubectl set env` lets you add env vars with a single command
4. **Rollouts are automatic** - Changing a Deployment's pod template triggers a rolling update

## Real-World Considerations

In production, you would:
- Store secrets in **Kubernetes Secrets** (not plain text in manifests)
- Use **ConfigMaps** for non-sensitive configuration
- Set up **health checks** (readiness/liveness probes)
- Use **rollback** if a change causes issues: `kubectl rollout undo deployment/escape-app`

```yaml
# Example: Using a Secret for DATABASE_URL
env:
  - name: DATABASE_URL
    valueFrom:
      secretKeyRef:
        name: app-secrets
        key: database-url
```
