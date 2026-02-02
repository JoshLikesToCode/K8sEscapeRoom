# Hints: RBAC Denied

---

## Hint Level 1: Where to Look

The pod is running but the application inside is failing. Check the logs to see what error it's getting:

```bash
kubectl logs escape-app -n escape-room-rbac-denied
```

You should see a "forbidden" error message. This is a Kubernetes RBAC (Role-Based Access Control) issue.

---

## Hint Level 2: What to Look For

The application is trying to call the Kubernetes API (specifically, to list pods). By default, ServiceAccounts have very limited permissions.

Check what ServiceAccount the pod is using:
```bash
kubectl get pod escape-app -n escape-room-rbac-denied -o jsonpath='{.spec.serviceAccountName}'
```

Then check what permissions that ServiceAccount has:
```bash
kubectl auth can-i list pods --as=system:serviceaccount:escape-room-rbac-denied:escape-sa -n escape-room-rbac-denied
```

---

## Hint Level 3: The Problem

The pod uses ServiceAccount `escape-sa`, which has no RBAC permissions configured. When the app tries to `kubectl get pods`, the API server rejects the request with "forbidden".

To grant permissions in Kubernetes, you need:
1. A **Role** (or ClusterRole) defining what actions are allowed
2. A **RoleBinding** (or ClusterRoleBinding) connecting the Role to the ServiceAccount

---

## Hint Level 4: How to Fix

Create a Role that allows listing pods, and a RoleBinding that grants it to the ServiceAccount.

```bash
# Create a Role that allows listing pods
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

After creating these, delete and recreate the pod (or wait for it to restart):
```bash
kubectl delete pod escape-app -n escape-room-rbac-denied
kubectl apply -f rooms/room-rbac-denied/app.yaml -n escape-room-rbac-denied
```
