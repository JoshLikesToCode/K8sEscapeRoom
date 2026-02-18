# Hints: CrashLoopBackOff - Missing Environment Variable

Use these hints progressively. Try to solve it yourself first!

---

## Hint Level 1: Where to Look

When a pod is in CrashLoopBackOff, it means the container keeps crashing after starting.

**Useful commands:**
```bash
# Check pod status and restart count
kubectl get pods -n escape-room-groundhog-deploy

# Look at recent events
kubectl describe deployment escape-app -n escape-room-groundhog-deploy
```

Look at the "Events" section at the bottom of the describe output.

---

## Hint Level 2: What to Look For

The container is crashing immediately after starting. This usually means:
- The application has a fatal error at startup
- A required configuration is missing

**Check the container logs:**
```bash
# Get the pod name from the deployment
kubectl logs -l app=escape-app -n escape-room-groundhog-deploy
```

The error message should tell you what's wrong.

---

## Hint Level 3: The Problem

The application requires a `DATABASE_URL` environment variable to start.

**You can fix this with a single command** using `kubectl set env` on the deployment.

To fix, you need to add an environment variable to the container.

---

## Hint Level 4: The Solution Approach

Use `kubectl set env` to add the missing environment variable to the deployment:

```bash
kubectl set env deployment/escape-app DATABASE_URL=postgres://localhost:5432/mydb -n escape-room-groundhog-deploy
```

This will trigger a rolling update and the new pod will start successfully.

See SOLUTION.md for the complete fix.
