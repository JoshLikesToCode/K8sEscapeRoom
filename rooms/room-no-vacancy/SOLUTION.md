# Solution: PVC Pending

## Root Cause

The StatefulSet's `volumeClaimTemplates` references a StorageClass named `fast-storage` that doesn't exist in this cluster:

```yaml
volumeClaimTemplates:
  - metadata:
      name: data
    spec:
      storageClassName: "fast-storage"   # <-- doesn't exist!
```

The manifests were migrated from a cloud cluster that had a `fast-storage` StorageClass for SSD-backed persistent volumes. This cluster only has the `standard` StorageClass.

Result: PVCs stay `Pending` → pods stay `Pending`.

## Diagnosis Steps

```bash
# Step 1: Pod is Pending
kubectl get pods -n escape-room-no-vacancy
# NAME           READY   STATUS    RESTARTS   AGE
# escape-app-0   0/1     Pending   0          5m

# Step 2: Describe pod — waiting for volume
kubectl describe pod escape-app-0 -n escape-room-no-vacancy
# Events:
#   Warning  FailedScheduling  pod has unbound immediate PersistentVolumeClaims

# Step 3: Check PVC — also Pending
kubectl get pvc -n escape-room-no-vacancy
# NAME                STATUS    STORAGECLASS   AGE
# data-escape-app-0   Pending   fast-storage   5m

# Step 4: Describe PVC — StorageClass not found
kubectl describe pvc data-escape-app-0 -n escape-room-no-vacancy
# Events:
#   Warning  ProvisioningFailed  storageclass.storage.k8s.io "fast-storage" not found

# Step 5: What StorageClasses exist? What provisioner do they use?
kubectl get sc
# NAME                 PROVISIONER             ...
# standard (default)   rancher.io/local-path   ...
```

## The Fix

Create a StorageClass named `fast-storage` with the same provisioner as `standard`:

First, check what provisioner and settings the existing `standard` StorageClass uses:

```bash
kubectl get sc standard -o yaml
```

Then create a StorageClass named `fast-storage` with the same provisioner and volumeBindingMode:

```bash
kubectl apply -f - <<'EOF'
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: fast-storage
provisioner: rancher.io/local-path
volumeBindingMode: WaitForFirstConsumer
EOF
```

That's it — no pods or PVCs to delete. The PVC binds once the StorageClass exists, and the pod schedules automatically.

## Verification

```bash
# Check PVC is now Bound
kubectl get pvc -n escape-room-no-vacancy
# NAME                STATUS   VOLUME       CAPACITY   STORAGECLASS
# data-escape-app-0   Bound    pvc-xxxxx    1Gi        fast-storage

# Check pod is Running
kubectl get pods -n escape-room-no-vacancy
# NAME           READY   STATUS    RESTARTS   AGE
# escape-app-0   1/1     Running   0          30s
```

## Lessons Learned

1. **StorageClasses are cluster-scoped** — they don't travel with namespace manifests
2. **Always check `kubectl get sc`** when PVCs are stuck Pending
3. **Manifests from other clusters may reference infrastructure that doesn't exist** — StorageClasses, IngressClasses, etc.
4. **StatefulSet volumeClaimTemplates are immutable** — you can't edit the StatefulSet to change the StorageClass; you must make the environment match
5. **Inspect existing resources** — `kubectl get sc standard -o yaml` tells you the provisioner you need

## Real-World Considerations

This happens constantly when:
- Migrating from cloud (EKS/GKE/AKS) to on-prem or local clusters
- Copying manifests between environments (staging → production)
- Using Helm charts that assume specific StorageClass names
- Setting up new clusters without matching the storage configuration

Prevention:
- Document required StorageClasses in your deployment prerequisites
- Use Helm values or Kustomize overlays to parameterize `storageClassName`
- Include StorageClass manifests in your infrastructure-as-code
- Use the default StorageClass where possible instead of naming one explicitly
