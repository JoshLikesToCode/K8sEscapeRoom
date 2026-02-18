# Hints: Access Denied

---

## Hint Level 1: Where to Look

The pod is running but the application inside is failing. Check the logs to see what error it's getting:

```bash
kubectl logs -l app=escape-app -n escape-room-rbac-denied
```

You should see a "forbidden" error message. This is a Kubernetes RBAC (Role-Based Access Control) issue.

---

## Hint Level 2: What to Look For

The application is trying to call the Kubernetes API (specifically, to list pods). By default, ServiceAccounts have very limited permissions.

Check what ServiceAccount the pod is using:
```bash
kubectl describe deployment escape-app -n escape-room-rbac-denied
```

Look for `Service Account` in the output. Then check what permissions that ServiceAccount has:
```bash
kubectl auth can-i list pods --as=system:serviceaccount:escape-room-rbac-denied:escape-sa -n escape-room-rbac-denied
```

---

## Hint Level 3: The Problem

The pod uses ServiceAccount `escape-sa`, which has no RBAC permissions configured. When the app tries to `kubectl get pods`, the API server rejects the request with "forbidden".

To grant permissions in Kubernetes, you need:
1. A **Role** defining what actions are allowed
2. A **RoleBinding** connecting the Role to the ServiceAccount

---

## Hint Level 4: How to Fix

Create a Role that allows listing pods, and a RoleBinding that grants it to the ServiceAccount:

```bash
kubectl create role pod-reader \
  --verb=get,list,watch \
  --resource=pods \
  -n escape-room-rbac-denied

kubectl create rolebinding pod-reader-binding \
  --role=pod-reader \
  --serviceaccount=escape-room-rbac-denied:escape-sa \
  -n escape-room-rbac-denied
```

Then delete the pod so the Deployment recreates it with the new permissions:

```bash
kubectl delete pod -l app=escape-app -n escape-room-rbac-denied
```
