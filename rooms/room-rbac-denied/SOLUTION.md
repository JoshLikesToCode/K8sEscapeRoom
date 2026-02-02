# Solution: RBAC Denied

## Root Cause

The pod runs with a ServiceAccount (`escape-sa`) that has no RBAC permissions. When the application tries to list pods using the Kubernetes API, the API server denies the request:

```
Error from server (Forbidden): pods is forbidden: User "system:serviceaccount:escape-room-rbac-denied:escape-sa" cannot list resource "pods" in API group "" in the namespace "escape-room-rbac-denied"
```

In Kubernetes, ServiceAccounts have no permissions by default. You must explicitly grant permissions using Role/RoleBinding (namespace-scoped) or ClusterRole/ClusterRoleBinding (cluster-wide).

## Diagnosis Steps

```bash
# Step 1: Check pod logs
kubectl logs escape-app -n escape-room-rbac-denied
# Shows: FAILED: Permission denied!

# Step 2: Identify the ServiceAccount
kubectl get pod escape-app -n escape-room-rbac-denied -o jsonpath='{.spec.serviceAccountName}'
# Output: escape-sa

# Step 3: Check current permissions
kubectl auth can-i list pods \
  --as=system:serviceaccount:escape-room-rbac-denied:escape-sa \
  -n escape-room-rbac-denied
# Output: no

# Step 4: Check if any roles/bindings exist
kubectl get roles,rolebindings -n escape-room-rbac-denied
# Output: No resources found
```

## The Fix

### Option 1: Create Role and RoleBinding Imperatively

```bash
# Create a Role that allows reading pods
kubectl create role pod-reader \
  --verb=get,list,watch \
  --resource=pods \
  -n escape-room-rbac-denied

# Bind the role to the ServiceAccount
kubectl create rolebinding pod-reader-binding \
  --role=pod-reader \
  --serviceaccount=escape-room-rbac-denied:escape-sa \
  -n escape-room-rbac-denied
```

### Option 2: Create Role and RoleBinding Declaratively

Create a file `rbac.yaml`:
```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: pod-reader
  namespace: escape-room-rbac-denied
rules:
  - apiGroups: [""]
    resources: ["pods"]
    verbs: ["get", "list", "watch"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: pod-reader-binding
  namespace: escape-room-rbac-denied
subjects:
  - kind: ServiceAccount
    name: escape-sa
    namespace: escape-room-rbac-denied
roleRef:
  kind: Role
  name: pod-reader
  apiGroup: rbac.authorization.k8s.io
```

Apply it:
```bash
kubectl apply -f rbac.yaml
```

### After Creating RBAC

The pod needs to be restarted to pick up the new permissions (or wait for it to restart on its own since it exits with failure):

```bash
kubectl delete pod escape-app -n escape-room-rbac-denied
# The pod will be recreated if using a Deployment, or reapply:
kubectl apply -f rooms/room-rbac-denied/app.yaml -n escape-room-rbac-denied
```

## Verification

```bash
# Check the RBAC resources exist
kubectl get roles,rolebindings -n escape-room-rbac-denied

# Verify permissions were granted
kubectl auth can-i list pods \
  --as=system:serviceaccount:escape-room-rbac-denied:escape-sa \
  -n escape-room-rbac-denied
# Output: yes

# Check the pod logs
kubectl logs escape-app -n escape-room-rbac-denied
# Should show: SUCCESS: Pod listing completed!
```

## Lessons Learned

1. **ServiceAccounts have no default permissions** beyond basic API discovery
2. **RBAC has two parts**: Role (what's allowed) + RoleBinding (who gets it)
3. **Namespace-scoped** (Role/RoleBinding) vs **cluster-scoped** (ClusterRole/ClusterRoleBinding)
4. Use `kubectl auth can-i` to test permissions without running the actual workload
5. Pods must be restarted to pick up new RBAC permissions

## Real-World Considerations

This commonly happens when:
- Deploying apps that need to interact with the Kubernetes API
- Operators and controllers that watch/manage resources
- CI/CD tools running in-cluster
- Monitoring tools that need to discover endpoints

Best practices:
- Follow principle of least privilege - only grant what's needed
- Use Roles (namespace-scoped) unless cluster-wide access is truly needed
- Audit RBAC permissions regularly
- Use `kubectl auth can-i --list` to see all permissions for a user/SA
- Consider using pre-defined ClusterRoles like `view`, `edit`, `admin` where appropriate
- Document required RBAC permissions in your application's deployment docs
