# Hints: PVC Pending

---

## Hint Level 1: Where to Look

The pod is Pending. Find out why:

```bash
kubectl describe pod escape-app-0 -n escape-room-pvc-pending
```

Look at the **Events** section. Is it waiting for something?

Also check if there are any PersistentVolumeClaims:
```bash
kubectl get pvc -n escape-room-pvc-pending
```

---

## Hint Level 2: The PVC Is Stuck

The PVC is also Pending. Describe it to see why:

```bash
kubectl describe pvc data-escape-app-0 -n escape-room-pvc-pending
```

The events will tell you exactly what's missing. Then check what StorageClasses are actually available in this cluster:

```bash
kubectl get storageclass
```

---

## Hint Level 3: Missing StorageClass

The PVC requests `storageClassName: "fast-storage"`, but that StorageClass doesn't exist. The cluster only has `standard`.

You need to create a StorageClass named `fast-storage`. Check what provisioner `standard` uses — yours needs the same one:

```bash
kubectl get sc standard -o yaml
```

Look for the `provisioner:` field.

---

## Hint Level 4: The Fix

Create a StorageClass named `fast-storage` with the same provisioner as `standard`:

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

The PVC will bind and the pod will start automatically.

See SOLUTION.md for the full walkthrough.
