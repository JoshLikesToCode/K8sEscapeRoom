# Solution: Ingress Misroute

## Root Cause

The Ingress resource references a service named `escape-svc`, but the actual service is named `escape-service`:

```yaml
# In the Ingress (WRONG):
backend:
  service:
    name: escape-svc      # Typo! Missing "-ervice"
    port:
      number: 80

# Actual service name:
metadata:
  name: escape-service    # Correct name
```

When the Ingress controller tries to route traffic to `escape-svc`, it can't find the service, resulting in a 404 or 503 error depending on the ingress controller.

## Diagnosis Steps

```bash
# Step 1: Verify pod and service are working
kubectl get pods,svc -n escape-room-bad-gateway
# Pod is Running, Service exists

# Step 2: Check the Ingress
kubectl get ingress -n escape-room-bad-gateway
kubectl describe ingress escape-ingress -n escape-room-bad-gateway
# Look at the "Rules" section and "Backends"

# Step 3: Compare service names
kubectl get svc -n escape-room-bad-gateway -o name
# Output: service/escape-service

kubectl get ingress escape-ingress -n escape-room-bad-gateway -o jsonpath='{.spec.rules[0].http.paths[0].backend.service.name}'
# Output: escape-svc  ← MISMATCH!

# Step 4: Test internal connectivity (should work)
kubectl run test-curl --rm -it --image=curlimages/curl --restart=Never \
  -n escape-room-bad-gateway -- curl -s http://escape-service
# Returns nginx welcome page - service works!
```

## The Fix

### Option 1: Patch the Ingress

```bash
kubectl patch ingress escape-ingress -n escape-room-bad-gateway \
  --type='json' \
  -p='[{"op": "replace", "path": "/spec/rules/0/http/paths/0/backend/service/name", "value": "escape-service"}]'
```

### Option 2: Edit the Ingress Directly

```bash
kubectl edit ingress escape-ingress -n escape-room-bad-gateway
```

Change:
```yaml
backend:
  service:
    name: escape-svc
```

To:
```yaml
backend:
  service:
    name: escape-service
```

### Option 3: Replace via YAML

```bash
kubectl get ingress escape-ingress -n escape-room-bad-gateway -o yaml | \
  sed 's/escape-svc/escape-service/g' | \
  kubectl apply -f -
```

## Verification

```bash
# Check the Ingress now references the correct service
kubectl describe ingress escape-ingress -n escape-room-bad-gateway

# If you have the ingress controller and /etc/hosts configured:
curl -H "Host: escape.local" http://localhost/api

# Or use port-forward to the ingress controller and test
# Or run a curl pod with the Host header:
kubectl run test-ingress --rm -it --image=curlimages/curl --restart=Never \
  -n escape-room-bad-gateway -- \
  curl -s -H "Host: escape.local" http://ingress-nginx-controller.ingress-nginx/api
```

## Lessons Learned

1. **Service names must match exactly** - typos cause routing failures
2. Ingress issues often result in 404/503 errors, not pod failures
3. Use `kubectl describe ingress` to see the resolved backends
4. Always verify the service name exists before referencing it in an Ingress
5. Internal connectivity (Service) can work while external (Ingress) fails

## Real-World Considerations

This commonly happens when:
- Copy-pasting Ingress configs and forgetting to update service names
- Service renamed but Ingress not updated
- Different naming conventions across teams (svc vs service)
- Auto-generated names don't match manual Ingress configs

Best practices:
- Use Helm/Kustomize to template service names consistently
- Validate Ingress backends exist before deployment
- Monitor Ingress controller logs for routing errors
- Use meaningful, consistent naming conventions
- Consider using ExternalName services for external dependencies
- Test Ingress rules in staging before production
