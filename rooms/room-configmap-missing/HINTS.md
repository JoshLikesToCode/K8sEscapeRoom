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

You need to create a ConfigMap named `app-config` with the environment variables the application expects. Look at the pod's command to see what variables it uses:
- APP_NAME
- APP_ENV
- LOG_LEVEL

Create a ConfigMap with these keys:
```bash
kubectl create configmap app-config \
  --from-literal=APP_NAME=escape-app \
  --from-literal=APP_ENV=production \
  --from-literal=LOG_LEVEL=info \
  -n escape-room-configmap-missing
```

The pod should automatically retry and start once the ConfigMap exists.
