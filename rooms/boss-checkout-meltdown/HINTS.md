# Hints: Checkout Meltdown (Boss Room)

**Warning:** This is a boss room with MULTIPLE failures. Fixing one problem won't be enough.

---

## Hint Level 1: Where to Look

There are TWO independent issues causing this outage. You need to investigate:

1. **Why does the Service have no endpoints?**
   ```bash
   kubectl get endpoints checkout-service -n escape-boss-checkout-meltdown
   ```

2. **Why are the pods showing 0/1 Ready?**
   ```bash
   kubectl get pods -n escape-boss-checkout-meltdown
   kubectl describe pod -l app=checkout-api -n escape-boss-checkout-meltdown
   ```

Both problems must be solved for the service to work.

---

## Hint Level 2: Problem #1 - No Endpoints

The Service can't find any pods to route traffic to. This happens when the Service selector doesn't match any pod labels.

Compare:
```bash
# What selector does the Service use?
kubectl describe svc checkout-service -n escape-boss-checkout-meltdown

# What labels do the pods have?
kubectl get pods -n escape-boss-checkout-meltdown --show-labels
```

Does the Service `Selector` match the pod labels exactly?

---

## Hint Level 3: Problem #2 - Pods Not Ready

Even after fixing the selector, pods won't receive traffic if they're not Ready. Check the readiness probe:

```bash
kubectl describe pod -l app=checkout-api -n escape-boss-checkout-meltdown
```

Scroll to the `Readiness` probe section. What port is it checking? Is that the port nginx actually listens on?

Also check the events at the bottom for probe failure messages.

---

## Hint Level 4: The Fixes

**Fix #1 - Service Selector:**
The Service selector is `app: checkout` but pods have `app: checkout-api`.

```bash
kubectl edit svc checkout-service -n escape-boss-checkout-meltdown
# Change: app: checkout
# To:     app: checkout-api
```

**Fix #2 - Readiness Probe Port:**
The probe checks port 8080 but nginx listens on port 80.

```bash
kubectl edit deployment checkout-api -n escape-boss-checkout-meltdown
# Change readinessProbe port from 8080 to 80
```

After both fixes, pods should become Ready and endpoints should appear.

See SOLUTION.md for alternative approaches.
