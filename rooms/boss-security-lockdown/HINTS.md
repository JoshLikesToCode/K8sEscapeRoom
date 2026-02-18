# Hints: Overzealous Warden (Boss Room)

**Warning:** This is a boss room with MULTIPLE failures. Fixing one problem will reveal another.

---

## Hint Level 1: Where to Look

The pod isn't starting at all. Start with the basics:

```bash
# Check pod status — what state is it in?
kubectl get pods -n escape-boss-security-lockdown

# Describe the pod for detailed error messages
kubectl describe pod -l app=escape-app -n escape-boss-security-lockdown
```

Look at the **Events** section and the **State** of the container. The error message tells you exactly what's wrong.

---

## Hint Level 2: The First Problem — runAsNonRoot

The error says: `container has runAsNonRoot and image will run as root`

This means:
- The security context requires the container to run as a non-root user
- But the nginx image defaults to running as root (UID 0)
- Kubernetes refuses to start the container

You need to tell Kubernetes which non-root user to run as. The `nginx:1.25-alpine` image has a built-in `nginx` user at UID 101.

```bash
kubectl describe deployment escape-app -n escape-boss-security-lockdown
```

Look at the `Pod Template` section for the security context settings.

---

## Hint Level 3: The Second Problem — Read-Only Filesystem

After fixing the user issue, the pod starts but immediately crashes. Check the logs:

```bash
kubectl logs -l app=escape-app -n escape-boss-security-lockdown
# Or if it already crashed:
kubectl logs -l app=escape-app -n escape-boss-security-lockdown --previous
```

nginx needs to write temp files, cache, and its PID file at startup. The nginx.conf already points all of these to `/tmp`, but `readOnlyRootFilesystem: true` makes the entire filesystem read-only — including `/tmp`.

You need to give the container a writable `/tmp` without removing the security setting.

---

## Hint Level 4: Both Fixes

Open the deployment in your editor — you can fix both bugs in one shot:

```bash
kubectl edit deployment escape-app -n escape-boss-security-lockdown
```

**Fix #1** — Find the `securityContext` block and add `runAsUser: 101`:

```yaml
          securityContext:
            runAsNonRoot: true
            runAsUser: 101              # <-- ADD THIS LINE
            readOnlyRootFilesystem: true
```

**Fix #2** — Find the existing `volumeMounts` list and append one entry, then find `volumes` and append a matching `emptyDir`:

```yaml
          volumeMounts:
            - mountPath: /etc/nginx/nginx.conf   # already here
              name: nginx-config                 # already here
              subPath: nginx.conf                # already here
              readOnly: true                     # already here
            - mountPath: /tmp                    # <-- ADD
              name: tmp                          # <-- ADD
```
```yaml
      volumes:
        - configMap:                             # already here
            name: nginx-config                   # already here
          name: nginx-config                     # already here
        - emptyDir: {}                           # <-- ADD
          name: tmp                              # <-- ADD
```

Save and close — a new pod rolls out automatically.

See SOLUTION.md for the full walkthrough.
