# Hints: Ingress Misroute

---

## Hint Level 1: Where to Look

The pod and service are working - the issue is with the Ingress configuration. Ingress resources route external traffic to services based on host and path rules.

Start by examining the Ingress:
```bash
kubectl describe ingress escape-ingress -n escape-room-ingress-misroute
```

Look at:
- The host rules
- The path rules
- The backend service reference

---

## Hint Level 2: What to Look For

Compare what the Ingress expects to route to versus what actually exists:

```bash
# What services exist?
kubectl get svc -n escape-room-ingress-misroute

# What does the Ingress reference?
kubectl get ingress escape-ingress -n escape-room-ingress-misroute -o yaml | grep -A10 backend
```

Does the service name in the Ingress match an actual service?

---

## Hint Level 3: The Problem

The Ingress backend references a service named `escape-svc`, but the actual service is named `escape-service`:

```yaml
# Ingress references (WRONG):
backend:
  service:
    name: escape-svc    # This doesn't exist!

# Actual service:
metadata:
  name: escape-service  # This is the real name
```

This is a common typo - service names must match exactly.

---

## Hint Level 4: How to Fix

Edit the Ingress to use the correct service name:

### Option A: Patch the Ingress
```bash
kubectl patch ingress escape-ingress -n escape-room-ingress-misroute \
  --type='json' \
  -p='[{"op": "replace", "path": "/spec/rules/0/http/paths/0/backend/service/name", "value": "escape-service"}]'
```

### Option B: Edit the Ingress directly
```bash
kubectl edit ingress escape-ingress -n escape-room-ingress-misroute
# Change: name: escape-svc
# To:     name: escape-service
```

After fixing, test by curling through the Ingress or checking the describe output for a valid backend.
