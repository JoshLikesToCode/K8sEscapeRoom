# INCIDENT: Registry Curse

**Severity:** P1 - Deployment Blocked
**Reported:** 09:15 UTC
**Status:** OPEN - Awaiting remediation

## Incident Summary

New application deployment is stuck. Pods cannot pull the container image from our private registry. The registry credentials secret was supposedly created, but the image still won't pull.

## Initial Report

> "I created the registry secret like the docs said, and I can see it exists, but the pod keeps showing ImagePullBackOff. I've recreated the secret three times. Something is cursed." — Frustrated developer

## What We Know

- The `escape-app` pod is stuck in `ImagePullBackOff`
- A secret named `registry-credentials` exists in the namespace
- The pod uses a ServiceAccount called `app-sa`
- The image is from our private registry: `private-registry.internal.example.com`
- **Previous fix attempts have focused on recreating the secret, but the problem persists**

## Triage Checklist

Start your investigation here:

```bash
# 1. Check pod status
kubectl get pods -n escape-boss-registry-curse

# 2. Check events for image pull errors
kubectl get events -n escape-boss-registry-curse --sort-by='.lastTimestamp'

# 3. Describe the pod for detailed error
kubectl describe pod escape-app -n escape-boss-registry-curse

# 4. Check what secrets exist
kubectl get secrets -n escape-boss-registry-curse

# 5. Check the ServiceAccount configuration
kubectl get sa app-sa -n escape-boss-registry-curse -o yaml

# 6. Check what imagePullSecrets the pod is actually using
kubectl get pod escape-app -n escape-boss-registry-curse -o jsonpath='{.spec.imagePullSecrets}'
```

## Success Criteria

- The ServiceAccount correctly references the existing secret (`registry-credentials`)
- The pod is running with a working image

**Note:** The private registry `private-registry.internal.example.com` is intentionally unreachable in this exercise. Once you fix the ServiceAccount configuration, you'll also need to change the pod's image to something publicly available (like `nginx:1.25-alpine`) to fully escape this room.

## Namespace

All resources are in the `escape-boss-registry-curse` namespace.

---

**On-call engineer, the secret exists but isn't being used. Why? There's a disconnect somewhere in the chain.**
