# Hints: Cascading Outage (Final Boss)

**Warning:** This is the FINAL BOSS. There are multiple initial failures AND an active threat making things worse. You must solve the meta-puzzle first.

---

## Hint Level 1: Where to Look

Check all deployments, services, and endpoints in the namespace. Not everything that's broken was broken from the start.

```bash
kubectl get deploy,svc,endpoints -n escape-final-cascading-outage
kubectl get pods -n escape-final-cascading-outage
```

Pay attention to which pods are Running, which are Ready, and which won't start at all.

---

## Hint Level 2: The Initial Bugs

There are two bugs that existed from the start:

1. **`frontend-svc` has no endpoints.** Compare the Service selector with the pod labels:
   ```bash
   kubectl get svc frontend-svc -n escape-final-cascading-outage -o jsonpath='{.spec.selector}'
   kubectl get pods -n escape-final-cascading-outage --show-labels
   ```

2. **`api-server` pods are stuck in `CreateContainerConfigError`.** They reference a Secret that doesn't exist:
   ```bash
   kubectl describe pods -l app=api-server -n escape-final-cascading-outage
   ```

---

## Hint Level 3: Something Is Wrong

Did you notice new failures appearing even after you started fixing things? The API readiness probe changed. A NetworkPolicy appeared. The database started crashing.

Something is actively sabotaging the cluster. Check for automation:

```bash
kubectl get cronjobs -n escape-final-cascading-outage
kubectl get jobs -n escape-final-cascading-outage
```

---

## Hint Level 4: Stop the Bleeding

There's a CronJob called `escalation-agent` that runs every minute and introduces new failures. **You must stop it before fixing anything else**, or your fixes will be undone.

```bash
kubectl delete cronjob escalation-agent -n escape-final-cascading-outage
```

---

## Hint Level 5: Full Cleanup Checklist

After deleting the CronJob, fix everything. Use `kubectl edit` to open resources in your editor:

1. **Fix `frontend-svc` selector** — change `app: frontend` to `app: web-frontend`:
   ```bash
   kubectl edit svc frontend-svc -n escape-final-cascading-outage
   # Change selector "app: frontend" to "app: web-frontend", save and quit
   ```
2. **Create the missing Secret** for `api-server`:
   ```bash
   kubectl create secret generic api-secrets \
     --from-literal=url="postgresql://db:5432/app" \
     -n escape-final-cascading-outage
   ```
3. **Fix api-server readiness probe** (if CronJob changed it) — the port should be `80`, not `9999`:
   ```bash
   kubectl edit deployment api-server -n escape-final-cascading-outage
   # Find the readinessProbe section, change port from 9999 to 80, save and quit
   ```
4. **Delete the NetworkPolicy** (if CronJob created it):
   ```bash
   kubectl delete networkpolicy deny-api-ingress -n escape-final-cascading-outage
   ```
5. **Fix database memory limits** (if CronJob reduced them) — requests should be `32Mi`, limits `64Mi`:
   ```bash
   kubectl edit deployment database -n escape-final-cascading-outage
   # Find resources section, change memory back to 32Mi/64Mi, save and quit
   ```

See SOLUTION.md for the complete walkthrough.
