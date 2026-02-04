# Hints: Registry Curse

**Warning:** This is a boss room with MULTIPLE issues. The obvious fix (recreating the secret) won't work.

---

## Hint Level 1: Where to Look

The image pull is failing, but the secret exists. The question is: **is the secret actually being used?**

Check the chain:
1. Pod → uses ServiceAccount
2. ServiceAccount → references imagePullSecrets
3. imagePullSecrets → should point to the Secret

```bash
# What ServiceAccount does the pod use?
kubectl get pod escape-app -n escape-boss-registry-curse -o jsonpath='{.spec.serviceAccountName}'

# What imagePullSecrets does that ServiceAccount have?
kubectl get sa app-sa -n escape-boss-registry-curse -o yaml
```

---

## Hint Level 2: Problem #1 - The Secret Reference

Compare the names carefully:

```bash
# What secrets exist?
kubectl get secrets -n escape-boss-registry-curse

# What secret does the ServiceAccount reference?
kubectl get sa app-sa -n escape-boss-registry-curse -o jsonpath='{.imagePullSecrets[*].name}'
```

Do these names match EXACTLY?

---

## Hint Level 3: Problem #2 - The Registry

Even with correct credentials, the image won't pull if the registry doesn't exist or the image name is wrong.

Check the image reference:
```bash
kubectl get pod escape-app -n escape-boss-registry-curse -o jsonpath='{.spec.containers[0].image}'
```

Is `private-registry.internal.example.com` a real registry? Can your cluster reach it?

For this escape room, you'll need to either:
- Fix the secret reference AND change the image to a public one
- Or at minimum, ensure the configuration is correct

---

## Hint Level 4: The Fixes

**Fix #1 - Correct ServiceAccount imagePullSecrets reference:**

The secret is `registry-credentials` but the SA references `registry-creds`.

```bash
kubectl patch sa app-sa -n escape-boss-registry-curse \
  --type='json' \
  -p='[{"op": "replace", "path": "/imagePullSecrets/0/name", "value": "registry-credentials"}]'
```

**Fix #2 - Use a working image:**

Since `private-registry.internal.example.com` doesn't exist, change to a public image:

```bash
kubectl get pod escape-app -n escape-boss-registry-curse -o yaml > pod.yaml
# Edit pod.yaml: change image to nginx:1.25-alpine
kubectl delete pod escape-app -n escape-boss-registry-curse
kubectl apply -f pod.yaml -n escape-boss-registry-curse
```

Or as a one-liner (delete and recreate with patched manifest):
```bash
kubectl delete pod escape-app -n escape-boss-registry-curse
kubectl run escape-app -n escape-boss-registry-curse \
  --image=nginx:1.25-alpine \
  --overrides='{"spec":{"serviceAccountName":"app-sa"}}' \
  --labels="app=escape-app"
```
