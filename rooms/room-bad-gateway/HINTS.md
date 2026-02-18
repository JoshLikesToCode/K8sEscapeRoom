# Hints: Bad Gateway

---

## Hint Level 1: Where to Look

The pod and service are working - the issue is with the Ingress configuration. Ingress resources route external traffic to services based on host and path rules.

Start by examining the Ingress:
```bash
kubectl describe ingress escape-ingress -n escape-room-bad-gateway
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
kubectl get svc -n escape-room-bad-gateway

# What does the Ingress reference?
kubectl describe ingress escape-ingress -n escape-room-bad-gateway
```

Compare the backend service name in the Ingress to the actual service name. Do they match?

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

```bash
kubectl edit ingress escape-ingress -n escape-room-bad-gateway
# Change: name: escape-svc
# To:     name: escape-service
```

After saving, verify the fix with `kubectl describe ingress escape-ingress -n escape-room-bad-gateway` — the backend error should be gone.

See SOLUTION.md for alternative approaches.
