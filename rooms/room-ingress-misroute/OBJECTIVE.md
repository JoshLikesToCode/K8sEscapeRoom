# Escape Room: Ingress Misroute

The application has been deployed with an Ingress for external access, but users report they can't reach the app. The pod and service seem to be working fine internally.

## Prerequisites

This room requires an **Ingress controller** to be installed in your cluster. If you're using kind, you can install nginx-ingress:

```bash
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/static/provider/kind/deploy.yaml
kubectl wait --namespace ingress-nginx \
  --for=condition=ready pod \
  --selector=app.kubernetes.io/component=controller \
  --timeout=90s
```

If you don't have an ingress controller, you can still solve this room by fixing the Ingress configuration - the escape tests will verify the config even without testing actual connectivity.

## Your Mission

1. Verify the pod and service are working internally
2. Investigate why the Ingress isn't routing traffic correctly
3. Fix the Ingress configuration so external traffic can reach the app

## Success Criteria

- The pod `escape-app` is in `Running` state
- Curling through the Ingress returns a successful response (HTTP 200)
- You can access the nginx welcome page via the Ingress

## Getting Started

```bash
# Check the pod and service
kubectl get pods,svc -n escape-room-ingress-misroute

# Check the Ingress
kubectl get ingress -n escape-room-ingress-misroute

# Try to reach the app via the ingress (if ingress controller is set up)
# Note: You may need to use port-forward or set up /etc/hosts
kubectl describe ingress escape-ingress -n escape-room-ingress-misroute
```

## Namespace

All resources are in the `escape-room-ingress-misroute` namespace.

Good luck, engineer. The app is running, but no one outside can find it.
