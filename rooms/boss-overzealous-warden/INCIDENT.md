# INCIDENT: Overzealous Warden (Boss Room)

**Severity:** P1 - Application Down
**Reported:** 09:15 UTC
**Status:** OPEN - Awaiting remediation

## Incident Summary

The security team hardened the production namespace overnight. This morning the `escape-app` deployment won't start. Pods are stuck and never become Ready.

## Initial Report

> "Security pushed new pod security policies last night. Now our nginx pods won't even start. We've been told we can't just remove the security settings — we need to make the app work *with* them." — On-call engineer

## What We Know

- The `escape-app` Deployment was redeployed with new security context settings
- Pods are NOT in Running state
- The security team requires `runAsNonRoot` and `readOnlyRootFilesystem` to stay enabled
- **There may be more than one issue — fixing the first problem could reveal another**

## Triage Checklist

Start your investigation here:

```bash
# 1. Get overall status
kubectl get all -n escape-boss-overzealous-warden

# 2. Check pod status and events
kubectl get pods -n escape-boss-overzealous-warden
kubectl describe pod -l app=escape-app -n escape-boss-overzealous-warden

# 3. Check the security context
kubectl get deployment escape-app -n escape-boss-overzealous-warden \
  -o jsonpath='{.spec.template.spec.containers[0].securityContext}' | jq .

# 4. Check events for clues
kubectl get events -n escape-boss-overzealous-warden --sort-by='.lastTimestamp'
```

## Success Criteria

- All `escape-app` pods are in `Running` state AND show `1/1` Ready
- `runAsNonRoot: true` is still set (don't just remove security)
- `readOnlyRootFilesystem: true` is still set (don't just remove security)

## Namespace

All resources are in the `escape-boss-overzealous-warden` namespace.

---

**On-call engineer, the security settings must stay. Make the app work within the constraints.**
