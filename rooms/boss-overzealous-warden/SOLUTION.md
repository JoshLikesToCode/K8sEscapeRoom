# Solution: Security Lockdown

## Root Causes (MULTIPLE)

This incident has **two layered failures** — the second is invisible until the first is fixed:

### Failure #1: runAsNonRoot Without runAsUser

```yaml
securityContext:
  runAsNonRoot: true    # Requires non-root user
  # runAsUser: ???      # But no user is specified!
```

The `nginx:1.25-alpine` image runs as root by default (UID 0). When `runAsNonRoot: true` is set without specifying a `runAsUser`, Kubernetes checks the image's default user, sees it's root, and refuses to start the container.

Result: `CreateContainerConfigError` — container never starts.

### Failure #2: Read-Only Filesystem Without Writable /tmp

```yaml
securityContext:
  readOnlyRootFilesystem: true  # Entire filesystem is read-only
  # No emptyDir volume for /tmp!
```

The nginx.conf is already configured to write its PID file, cache, and all temp files to `/tmp`. But `readOnlyRootFilesystem: true` makes `/tmp` read-only along with everything else. nginx crashes immediately on startup.

Result: `CrashLoopBackOff` — container starts but crashes on first write.

**Why this is tricky:** Bug #2 is completely hidden while Bug #1 is active. The container never starts, so you never see the filesystem error.

## Diagnosis Steps

```bash
# Step 1: Check pod status — notice CreateContainerConfigError
kubectl get pods -n escape-boss-overzealous-warden
# NAME                          READY   STATUS                       RESTARTS   AGE
# escape-app-xxxxx              0/1     CreateContainerConfigError   0          5m

# Step 2: Describe pod for the error message
kubectl describe pod -l app=escape-app -n escape-boss-overzealous-warden
# Events:
#   Warning  Failed  container has runAsNonRoot and image will run as root

# Step 3: Check the security context
kubectl get deployment escape-app -n escape-boss-overzealous-warden \
  -o jsonpath='{.spec.template.spec.containers[0].securityContext}'
# {"readOnlyRootFilesystem":true,"runAsNonRoot":true}
# Notice: no runAsUser!

# Step 4: After fixing runAsUser, pod crashes — check logs
kubectl logs -l app=escape-app -n escape-boss-overzealous-warden --previous
# nginx: [emerg] open() "/tmp/nginx.pid" failed (30: Read-only file system)
```

## The Fix

Open the deployment in your editor:

```bash
kubectl edit deployment escape-app -n escape-boss-overzealous-warden
```

You can fix both bugs in one edit. Here's what to change — lines marked with `# <-- ADD` are the only additions:

```yaml
    spec:
      containers:
        - name: nginx
          # ...
          volumeMounts:
            - mountPath: /etc/nginx/nginx.conf   # already exists
              name: nginx-config                  # already exists
              subPath: nginx.conf                 # already exists
              readOnly: true                      # already exists
            - mountPath: /tmp                     # <-- ADD
              name: tmp                           # <-- ADD
          securityContext:
            runAsNonRoot: true
            runAsUser: 101                        # <-- ADD (nginx user in alpine)
            readOnlyRootFilesystem: true
      volumes:
        - configMap:                              # already exists
            name: nginx-config                    # already exists
          name: nginx-config                      # already exists
        - emptyDir: {}                            # <-- ADD
          name: tmp                               # <-- ADD
```

Save and close — Kubernetes rolls out a new pod automatically.

**What each change does:**
- `runAsUser: 101` — tells Kubernetes to run the container as the nginx user (UID 101) instead of root, satisfying `runAsNonRoot`
- `emptyDir` at `/tmp` — provides a writable directory for nginx's PID file, cache, and temp files, while the rest of the filesystem stays read-only

## Verification

```bash
# Wait for rollout
kubectl rollout status deployment/escape-app -n escape-boss-overzealous-warden

# Check pods are Running and Ready
kubectl get pods -n escape-boss-overzealous-warden
# NAME                          READY   STATUS    RESTARTS   AGE
# escape-app-xxxxx              1/1     Running   0          30s

# Verify security context is still enforced
kubectl get deployment escape-app -n escape-boss-overzealous-warden \
  -o jsonpath='{.spec.template.spec.containers[0].securityContext}'
# Should still have runAsNonRoot: true AND readOnlyRootFilesystem: true
```

## Lessons Learned

1. **Layered failures hide each other** — the container must start before filesystem errors appear
2. **`runAsNonRoot` requires explicit `runAsUser`** when the image defaults to root
3. **`readOnlyRootFilesystem` requires writable volumes** for any directory the app writes to
4. **Consolidate writable paths to `/tmp`** — a single emptyDir is simpler than many
5. **Don't remove security to fix issues** — work within the constraints using volumes and user settings

## Real-World Considerations

This pattern is extremely common in production:
- Pod Security Standards (PSS) enforce `runAsNonRoot` at the namespace level
- CIS benchmarks recommend `readOnlyRootFilesystem` for all containers
- Many popular images (nginx, redis, postgres) default to running as root
- Teams often enable security policies without testing existing deployments

Prevention:
- Use distroless or non-root base images
- Always specify `runAsUser` alongside `runAsNonRoot`
- Test with `readOnlyRootFilesystem: true` during development
- Configure apps to write all temp/cache/pid files under `/tmp`
- Use Pod Security Admission to catch misconfigurations before deployment
