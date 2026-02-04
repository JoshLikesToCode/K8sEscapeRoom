# INCIDENT: Checkout Meltdown

**Severity:** P1 - Revenue Impact
**Reported:** 14:32 UTC
**Status:** OPEN - Awaiting remediation

## Incident Summary

Customers cannot complete purchases. The checkout API was deployed 15 minutes ago and has been returning errors ever since. Cart abandonment is spiking.

## Initial Report

> "We deployed the new checkout-api and it shows as running in the dashboard, but customers are getting 503 errors. I checked and the pods are up. No idea what's happening." — On-call engineer

## What We Know

- The `checkout-api` deployment was applied successfully
- Pods show status `Running` in `kubectl get pods`
- The `checkout-service` Service exists
- Customers hitting the service get 503 Service Unavailable
- **Multiple teams have looked at this and fixed "their part" but it's still broken**

## Triage Checklist

Start your investigation here:

```bash
# 1. Get overall status
kubectl get all -n escape-boss-checkout-meltdown

# 2. Check pod readiness (READY column)
kubectl get pods -n escape-boss-checkout-meltdown

# 3. Check service endpoints
kubectl get endpoints checkout-service -n escape-boss-checkout-meltdown

# 4. Check events for clues
kubectl get events -n escape-boss-checkout-meltdown --sort-by='.lastTimestamp'

# 5. Describe the service and pods
kubectl describe svc checkout-service -n escape-boss-checkout-meltdown
kubectl describe pod -l app=checkout-api -n escape-boss-checkout-meltdown
```

## Success Criteria

- All `checkout-api` pods are in `Running` state AND show `1/1` Ready
- The `checkout-service` has endpoints (not `<none>`)
- Curling the service returns HTTP 200

## Namespace

All resources are in the `escape-boss-checkout-meltdown` namespace.

---

**On-call engineer, there's more than one thing broken here. Find them all, or customers keep seeing errors.**
