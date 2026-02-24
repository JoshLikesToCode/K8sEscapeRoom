# Solution: Cascading Outage (Final Boss)

## Overview

This room simulates a production incident where a 3-tier application (frontend, API, database) has initial deployment bugs **plus** a rogue CronJob (`escalation-agent`) that progressively introduces new failures every 60 seconds.

The meta-puzzle is discovering and stopping the CronJob before attempting fixes.

## Step 1: Triage — Assess Initial State

```bash
kubectl get all -n escape-final-cascading-outage
kubectl get pods -n escape-final-cascading-outage
kubectl get svc,endpoints -n escape-final-cascading-outage
```

You should observe:
- `frontend` pods: Running but `frontend-svc` has 0 endpoints
- `api-server` pods: `CreateContainerConfigError`
- `database` pods: Running and Ready (initially healthy)

## Step 2: Discover the CronJob

As you investigate and attempt fixes, you'll notice new failures appearing:
- The api-server readiness probe changes to an unreachable port
- A NetworkPolicy blocks traffic to api-server
- The database starts OOMKilling

This is the clue that something is actively sabotaging the cluster:

```bash
kubectl get cronjobs -n escape-final-cascading-outage
kubectl get jobs -n escape-final-cascading-outage
kubectl logs job/<latest-job-name> -n escape-final-cascading-outage
```

You'll find `escalation-agent` — a CronJob running every minute that reads its current step from a ConfigMap and executes the next escalation.

## Step 3: Stop the CronJob (Critical First Step)

**This must be done before any other fixes, or your work will be undone.**

```bash
# Delete the CronJob
kubectl delete cronjob escalation-agent -n escape-final-cascading-outage

# Also kill any currently running job
kubectl delete jobs --all -n escape-final-cascading-outage
```

## Step 4: Fix Initial Bug #1 — Frontend Service Selector

The `frontend-svc` selects `app: frontend` but pods have label `app: web-frontend`.

```bash
kubectl edit svc frontend-svc -n escape-final-cascading-outage
```

In your editor, find the `selector` section and change `app: frontend` to `app: web-frontend`. Save and quit.

Verify:
```bash
kubectl get endpoints frontend-svc -n escape-final-cascading-outage
```

## Step 5: Fix Initial Bug #2 — Create Missing Secret

The `api-server` deployment references Secret `api-secrets` key `url` which doesn't exist.

```bash
kubectl create secret generic api-secrets \
  --from-literal=url="postgresql://database-svc:5432/app" \
  -n escape-final-cascading-outage
```

After creating the Secret, the api-server pods should start. But if the CronJob already ran Step 1, the readiness probe will be wrong — continue to Step 6.

## Step 6: Undo CronJob Damage

Depending on how long the CronJob ran, you may need to fix some or all of the following:

### 6a: Fix api-server readiness probe (Step 1 damage — port 9999)

```bash
kubectl edit deployment api-server -n escape-final-cascading-outage
```

Find the `readinessProbe` section and change `port: 9999` to `port: 80`. Save and quit.

### 6b: Delete the deny-api-ingress NetworkPolicy (Step 2 damage)

```bash
kubectl delete networkpolicy deny-api-ingress -n escape-final-cascading-outage
```

### 6c: Fix database memory limits (Step 3 damage — 4Mi causing OOMKill)

```bash
kubectl edit deployment database -n escape-final-cascading-outage
```

Find the `resources` section and change memory back — requests: `32Mi`, limits: `64Mi`. Save and quit.

## Step 7: Verification

```bash
# All pods should be Running and Ready (1/1)
kubectl get pods -n escape-final-cascading-outage

# All services should have endpoints
kubectl get endpoints -n escape-final-cascading-outage

# CronJob should be gone
kubectl get cronjobs -n escape-final-cascading-outage

# No NetworkPolicy blocking traffic
kubectl get networkpolicy -n escape-final-cascading-outage
```

Expected final state:
- `frontend` — 1/1 Ready, `frontend-svc` has endpoints
- `api-server` — 2/2 Ready, `api-svc` has endpoints
- `database` — 1/1 Ready, `database-svc` has endpoints
- `escalation-agent` CronJob — suspended or deleted
- No `deny-api-ingress` NetworkPolicy
- No pods in OOMKilled or CrashLoopBackOff

## Lessons Learned

1. **Cascading failures are real** — In production, one failure often triggers or masks others. Systematic triage is essential.
2. **Rogue automation is dangerous** — CronJobs, operators, and CI/CD pipelines can actively work against you during an incident. Always check for automated processes.
3. **Stop the bleeding first** — Before fixing individual symptoms, identify and stop the root cause of ongoing damage.
4. **Observe before acting** — If fixes don't stick, something is undoing your work. Step back and look at the bigger picture.
