# Hints: Room Full

Use these hints progressively. Try to solve it yourself first!

---

## Hint Level 1: Understanding Pending

When a pod is `Pending`, it means the Kubernetes scheduler cannot find a node to run it on.

**Common causes:**
- Insufficient CPU or memory on nodes
- Node selectors or affinity rules don't match
- Taints and tolerations issues
- PersistentVolume claims not bound

**Useful commands:**
```bash
kubectl describe pod escape-app -n escape-room-full
```

Look at the "Events" section - the scheduler will tell you why it can't schedule.

---

## Hint Level 2: Reading the Events

The events should show something like:
```
Warning  FailedScheduling  0/1 nodes are available: 1 Insufficient memory, 1 Insufficient cpu.
```

This tells you the pod is requesting more resources than any node has available.

**Check what resources the pod is requesting:**
```bash
kubectl describe pod escape-app -n escape-room-full
```

Look for the `Requests` section under the container — it shows CPU and memory.

---

## Hint Level 3: The Problem

The pod is requesting:
- 64Gi of memory
- 32 CPU cores

A kind cluster node typically has much less than this available!

**Check what your nodes actually have:**
```bash
kubectl describe node
```

Scroll to the `Allocatable` section to see available CPU and memory.

---

## Hint Level 4: How to Fix

You need to reduce the resource requests to something the node can handle.

**Reasonable values for a kind cluster:**
```yaml
resources:
  requests:
    memory: "128Mi"
    cpu: "100m"
  limits:
    memory: "256Mi"
    cpu: "500m"
```

You'll need to delete the pod and recreate it with lower resource requests.

See SOLUTION.md for the complete fix.
