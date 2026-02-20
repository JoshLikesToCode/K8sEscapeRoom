# INCIDENT: Cascading Outage

```
==========================================================
  SEVERITY:   P0 — FULL PLATFORM OUTAGE
  REPORTED:   03:47 UTC
  STATUS:     ACTIVE — SITUATION DETERIORATING
  COMMANDER:  You
==========================================================
```

## Incident Summary

The e-commerce platform was redeployed 10 minutes ago. Every tier is broken or degraded. Revenue is at zero. The CEO is on the bridge call. And the system is getting *worse* — not better.

## Initial Report

> "I don't know what's happening. I fixed the frontend five minutes ago and now the database is crashing. I've never seen this before. It's like something is actively fighting us."
>
> — On-call engineer (who has been awake since 2am)

## What We Know

- The platform has three tiers: `frontend`, `api-server`, and `database`
- The `frontend` pods are Running but the Service can't route to them
- The `api-server` pods won't even start — something about a missing config
- The `database` was healthy initially but may now be degraded
- **Engineers report that fixes don't stick. New problems keep appearing.**
- This is not a normal outage.

## Triage Checklist

```bash
# 1. Assess the damage
kubectl get all -n escape-final-cascading-outage

# 2. Check what's running and what's not
kubectl get pods -n escape-final-cascading-outage

# 3. Check if services can actually reach their pods
kubectl get endpoints -n escape-final-cascading-outage

# 4. Look at recent events for clues
kubectl get events -n escape-final-cascading-outage --sort-by='.lastTimestamp'

# 5. Describe anything that looks broken
kubectl describe pods -n escape-final-cascading-outage
```

## Success Criteria

- All three tiers have pods `Running` and `1/1 Ready`
- All three Services have endpoints
- No rogue automation running in the namespace
- No pods in `OOMKilled` or `CrashLoopBackOff`

## Namespace

```
escape-final-cascading-outage
```

---

**Stop. Before you fix anything — ask yourself: why is it getting worse?**
