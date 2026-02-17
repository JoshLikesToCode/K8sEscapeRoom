# Escape Room: PVC Pending

The application's StatefulSet pod is stuck in `Pending` state. The previous team migrated these manifests from a cloud cluster, but something about the storage configuration doesn't match this environment.

## Your Mission

1. Identify why the pod cannot be scheduled
2. Understand what the pod's storage needs and what the cluster provides
3. Fix the storage configuration so the pod can run

## Success Criteria

- The `escape-app-0` pod is in `Running` state and shows `1/1` Ready
- The PersistentVolumeClaim is `Bound`

## Getting Started

```bash
# Check the pod status
kubectl get pods -n escape-room-pvc-pending

# Check all resources including PVCs
kubectl get all,pvc -n escape-room-pvc-pending

# What storage infrastructure does this cluster have?
kubectl get storageclass
```

## Useful Reference

A StorageClass tells Kubernetes how to provision storage. You can inspect any existing StorageClass to see how it's configured:

```bash
kubectl get sc <name> -o yaml
```

The key fields are `provisioner` (which backend creates the volumes) and `volumeBindingMode` (when to bind). If you need to create a new StorageClass, a minimal definition looks like:

```yaml
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: <name>
provisioner: <copy-from-existing-sc>
volumeBindingMode: <copy-from-existing-sc>
```

## Namespace

All resources are in the `escape-room-pvc-pending` namespace.

Good luck, engineer. The pod needs its storage before it can start.
