# Hints: 404: Room Not Found

Use these hints progressively. Try to solve it yourself first!

---

## Hint Level 1: Understanding the Status

When a pod shows `ImagePullBackOff` or `ErrImagePull`, Kubernetes cannot download the container image.

**Common causes:**
- Image name is misspelled
- Image tag doesn't exist
- Private registry without credentials
- Network issues

**Useful commands:**
```bash
kubectl describe pod escape-app -n escape-room-imagepullbackoff
```

Look at the "Events" section at the bottom.

---

## Hint Level 2: Finding the Issue

The events should show a message like:
```
Failed to pull image "nginx:latset": rpc error: ... manifest unknown
```

**Look closely at the image name.** Is there a typo?

The `kubectl describe` output shows the image name near the top under `Containers`. Read it carefully.

---

## Hint Level 3: The Problem

The image tag is `nginx:latset` - notice the typo!

It should be `nginx:latest` (or another valid tag like `nginx:1.25`).

You can verify available tags at: https://hub.docker.com/_/nginx/tags

---

## Hint Level 4: How to Fix

You cannot edit the image of a running pod. You must delete and recreate it.

**Option 1: Delete and apply fixed manifest**
```bash
kubectl delete pod escape-app -n escape-room-imagepullbackoff
# Then apply a corrected YAML
```

**Option 2: Use kubectl run**
```bash
kubectl delete pod escape-app -n escape-room-imagepullbackoff
kubectl run escape-app -n escape-room-imagepullbackoff --image=nginx:latest --port=80
```

See SOLUTION.md for the complete fix.
