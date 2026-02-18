# Hints: Out of Service

---

## Hint Level 1: Where to Look

The pod is running fine - this isn't a pod problem. The issue is with how the Service finds pods to send traffic to.

Check the endpoints for the service:
```bash
kubectl get endpoints escape-service -n escape-room-service-selector-mismatch
```

If endpoints show `<none>`, the Service can't find any matching pods.

---

## Hint Level 2: What to Look For

Services find pods using label selectors. The Service's selector must match the pod's labels exactly.

Compare these two things:
```bash
# What labels does the pod have?
kubectl get pods -n escape-room-service-selector-mismatch --show-labels

# What selector does the service use?
kubectl describe svc escape-service -n escape-room-service-selector-mismatch
```

Compare the `Selector` field on the service to the pod's labels. Do they match exactly?

---

## Hint Level 3: The Problem

The Service selector is looking for pods with label `app: escapeapp` (no hyphen), but the actual pod has label `app: escape-app` (with hyphen).

This is a common typo that's easy to miss:
- Pod label: `app: escape-app`
- Service selector: `app: escapeapp`  ← missing the hyphen!

---

## Hint Level 4: How to Fix

Edit the Service to fix the selector typo:

```bash
kubectl edit svc escape-service -n escape-room-service-selector-mismatch
# Change: app: escapeapp
# To:     app: escape-app
```

After saving, verify endpoints appear:
```bash
kubectl get endpoints escape-service -n escape-room-service-selector-mismatch
```

See SOLUTION.md for alternative approaches.
