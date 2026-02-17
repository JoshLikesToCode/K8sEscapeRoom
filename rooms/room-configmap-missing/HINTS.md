# Hints: ConfigMap Missing

---

## Hint Level 1: Where to Look

The pod status shows `CreateContainerConfigError`. This error occurs before the container even starts - something in the pod specification is referencing a resource that doesn't exist.

Try these commands to investigate:
```bash
kubectl describe pod escape-app -n escape-room-configmap-missing
kubectl get events -n escape-room-configmap-missing
```

Look at the Events section at the bottom of the describe output.

---

## Hint Level 2: What to Look For

The error message in the events will tell you exactly what's missing. Look for phrases like:
- "configmap ... not found"
- "secret ... not found"

Check the pod spec to see what external resources it references:
```bash
kubectl get pod escape-app -n escape-room-configmap-missing -o yaml
```

Look for `envFrom`, `env.valueFrom`, or `volumes` sections.

---

## Hint Level 3: The Problem

The pod is configured to load environment variables from a ConfigMap called `app-config` using `envFrom.configMapRef`. However, this ConfigMap doesn't exist in the namespace.

Verify the ConfigMap is missing:
```bash
kubectl get configmaps -n escape-room-configmap-missing
```

---

## Hint Level 4: How to Fix

You need to create the missing ConfigMap. The pod will automatically retry and start once it exists.

```bash
kubectl create configmap app-config -n escape-room-configmap-missing
```

See SOLUTION.md for best practices on populating ConfigMap values.
