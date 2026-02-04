# INCIDENT: Slow Death

**Severity:** P2 - Service Degradation
**Reported:** 03:47 UTC
**Status:** OPEN - Intermittent failures

## Incident Summary

Application pod keeps dying but from different causes each time. Sometimes it's OOMKilled, sometimes Kubernetes kills it for being "unhealthy." The pod works in development but fails in production-like conditions.

## Initial Report

> "The pod starts up and sometimes works for a few seconds, then dies. I've checked the logs and sometimes it says out of memory, other times it just gets killed. I can't figure out a pattern." — Night shift engineer

## What We Know

- The `escape-app` pod is in `CrashLoopBackOff` with multiple restarts
- Container termination reasons alternate between `OOMKilled` and `Error`
- Events show both memory issues AND probe failures
- The same pod definition "works fine" locally with Docker
- **This feels like multiple problems, not one**

## Triage Checklist

Start your investigation here:

```bash
# 1. Check pod status and restart count
kubectl get pods -n escape-boss-slow-death

# 2. Check the termination reason of the last failure
kubectl get pod escape-app -n escape-boss-slow-death -o jsonpath='{.status.containerStatuses[0].lastState.terminated.reason}'

# 3. Check ALL events (you'll see multiple failure types)
kubectl get events -n escape-boss-slow-death --sort-by='.lastTimestamp'

# 4. Check resource configuration
kubectl get pod escape-app -n escape-boss-slow-death -o jsonpath='{.spec.containers[0].resources}'

# 5. Check liveness probe configuration
kubectl get pod escape-app -n escape-boss-slow-death -o jsonpath='{.spec.containers[0].livenessProbe}'

# 6. Check container state history
kubectl describe pod escape-app -n escape-boss-slow-death | grep -A20 "Last State:"
```

## Success Criteria

- Pod is in `Running` state and `Ready`
- Pod is stable (restart count not increasing)
- No OOMKilled events
- No liveness probe failures

## Namespace

All resources are in the `escape-boss-slow-death` namespace.

---

**On-call engineer, this pod is dying multiple ways. You need to fix ALL the resource and probe issues, or it will keep finding new ways to fail.**
