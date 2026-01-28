# Hints: CrashLoopBackOff - Missing Environment Variable

Use these hints progressively. Try to solve it yourself first!

---

## Hint Level 1: Where to Look

When a pod is in CrashLoopBackOff, it means the container keeps crashing after starting.

**Useful commands:**
```bash
# Check pod status and restart count
kubectl get pods -n escape-room-crashloop-env

# Look at recent events
kubectl describe pod escape-app -n escape-room-crashloop-env
```

Look at the "Events" section at the bottom of the describe output.

---

## Hint Level 2: What to Look For

The container is crashing immediately after starting. This usually means:
- The application has a fatal error at startup
- A required configuration is missing

**Check the container logs:**
```bash
kubectl logs escape-app -n escape-room-crashloop-env
```

The error message should tell you what's wrong.

---

## Hint Level 3: The Problem

The application requires a `DATABASE_URL` environment variable to start.

**Your options to fix this:**

1. **Edit the pod directly** (delete and recreate with the fix)
2. **Use kubectl set env** (won't work on a pod - only deployments)
3. **Patch the pod spec** (must delete and recreate)

To fix, you need to add an environment variable to the container.

---

## Hint Level 4: The Solution Approach

You cannot edit a running pod's environment variables. You must:

1. Export the current pod definition
2. Add the missing environment variable
3. Delete the old pod
4. Apply the fixed definition

```bash
# Get the current pod definition
kubectl get pod escape-app -n escape-room-crashloop-env -o yaml > fixed-pod.yaml

# Edit fixed-pod.yaml to add the DATABASE_URL env var
# Then delete and reapply
```

See SOLUTION.md for the complete fix.
