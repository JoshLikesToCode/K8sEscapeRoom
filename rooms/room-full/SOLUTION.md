# Solution: Pending - Resource Requests Exceed Capacity

## Root Cause

The pod requests 64Gi of memory and 32 CPU cores - far more than any node in a kind cluster can provide. The scheduler cannot find a suitable node, so the pod remains Pending indefinitely.

## Diagnosis Steps

```bash
# 1. Check pod status - see Pending
kubectl get pods -n escape-room-full
# NAME         READY   STATUS    RESTARTS   AGE
# escape-app   0/1     Pending   0          2m

# 2. Describe the pod to see scheduler events
kubectl describe pod escape-app -n escape-room-full

# Look for events like:
# Events:
#   Type     Reason            Age   From               Message
#   ----     ------            ----  ----               -------
#   Warning  FailedScheduling  30s   default-scheduler  0/1 nodes are available:
#            1 Insufficient cpu, 1 Insufficient memory. preemption: 0/1 nodes are available:
#            1 No preemption victims found for incoming pod.

# 3. Check what resources the pod is requesting
kubectl get pod escape-app -n escape-room-full \
  -o jsonpath='{.spec.containers[0].resources.requests}'
# Output: {"cpu":"32","memory":"64Gi"}

# 4. Check what resources are available on nodes
kubectl describe nodes | grep -A 6 "Allocatable:"
# Allocatable:
#   cpu:                8          # Much less than 32!
#   memory:             8052956Ki  # About 8Gi, much less than 64Gi!
```

## The Fix

### Option 1: Quick Fix with kubectl run

```bash
# Delete the broken pod
kubectl delete pod escape-app -n escape-room-full

# Create a new pod with reasonable resource requests
kubectl run escape-app -n escape-room-full \
  --image=nginx:1.25 \
  --port=80 \
  --requests='cpu=100m,memory=128Mi' \
  --limits='cpu=500m,memory=256Mi'
```

### Option 2: Apply Corrected YAML

```bash
# Delete the broken pod
kubectl delete pod escape-app -n escape-room-full

# Apply the fixed manifest
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: escape-app
  namespace: escape-room-full
  labels:
    app: escape-app
    room: pending-resources
spec:
  containers:
    - name: app
      image: nginx:1.25
      ports:
        - containerPort: 80
      resources:
        requests:
          memory: "128Mi"
          cpu: "100m"
        limits:
          memory: "256Mi"
          cpu: "500m"
EOF
```

## Verification

```bash
# Check the pod is now running
kubectl get pods -n escape-room-full
# NAME         READY   STATUS    RESTARTS   AGE
# escape-app   1/1     Running   0          30s

# Verify scheduling succeeded by checking events
kubectl describe pod escape-app -n escape-room-full | grep -A 3 "Events:"
# Should show: Successfully assigned, Pulled, Created, Started
```

## Lessons Learned

1. **Pending always has a reason** - Check `kubectl describe pod` for scheduler messages
2. **Know your node capacity** - Use `kubectl describe nodes` to see available resources
3. **Right-size your requests** - Requests should match actual usage, not arbitrary large numbers
4. **Requests vs Limits**:
   - **Requests**: Used for scheduling; pod guaranteed these resources
   - **Limits**: Maximum the container can use; enforced at runtime

## Real-World Considerations

### Resource Planning
```bash
# Check total cluster capacity
kubectl top nodes

# Check resource usage of running pods
kubectl top pods --all-namespaces

# See resource quotas in a namespace
kubectl describe resourcequota -n <namespace>
```

### Best Practices

1. **Set appropriate requests and limits**
   ```yaml
   resources:
     requests:
       memory: "128Mi"   # What the app needs to run
       cpu: "100m"       # 0.1 CPU cores
     limits:
       memory: "256Mi"   # Max before OOM kill
       cpu: "500m"       # Max CPU throttling
   ```

2. **Use LimitRanges to set defaults**
   ```yaml
   apiVersion: v1
   kind: LimitRange
   metadata:
     name: default-limits
   spec:
     limits:
       - default:
           memory: "256Mi"
           cpu: "500m"
         defaultRequest:
           memory: "128Mi"
           cpu: "100m"
         type: Container
   ```

3. **Use ResourceQuotas to prevent overcommitment**
   ```yaml
   apiVersion: v1
   kind: ResourceQuota
   metadata:
     name: namespace-quota
   spec:
     hard:
       requests.cpu: "4"
       requests.memory: "8Gi"
       limits.cpu: "8"
       limits.memory: "16Gi"
   ```

### Cluster Autoscaling

In cloud environments, if a pod can't be scheduled due to resource constraints, a cluster autoscaler can automatically add more nodes. But this doesn't help if the pod requests more than a single node can provide!
