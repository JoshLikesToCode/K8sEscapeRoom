# Hints: The Vault is Empty

---

## Hint Level 1: Where to Look

The pod status shows `CreateContainerConfigError`. This error occurs before the container starts - something in the pod specification references a resource that doesn't exist.

Try these commands to investigate:
```bash
kubectl describe pod escape-app -n escape-room-secret-missing
kubectl get events -n escape-room-secret-missing
```

Look at the Events section at the bottom of the describe output.

---

## Hint Level 2: What to Look For

The error message in the events will tell you exactly what's missing. The pod is trying to load an environment variable from a Secret.

Check the pod spec to see what it references:
```bash
kubectl describe pod escape-app -n escape-room-secret-missing
```

Look at the `Environment` section — it shows where each env var is loaded from.

---

## Hint Level 3: The Problem

The pod has an environment variable `DATABASE_PASSWORD` that's configured to read from a Secret called `db-credentials` (key: `password`). However, this Secret doesn't exist in the namespace.

Verify the Secret is missing:
```bash
kubectl get secrets -n escape-room-secret-missing
```

---

## Hint Level 4: How to Fix

You need to create a Secret named `db-credentials` with a `password` key.

Create it imperatively:
```bash
kubectl create secret generic db-credentials \
  --from-literal=password=supersecretpassword123 \
  -n escape-room-secret-missing
```

Or create it declaratively with base64-encoded data:
```yaml
apiVersion: v1
kind: Secret
metadata:
  name: db-credentials
  namespace: escape-room-secret-missing
type: Opaque
data:
  password: c3VwZXJzZWNyZXRwYXNzd29yZDEyMw==
```

The pod should automatically retry and start once the Secret exists.
