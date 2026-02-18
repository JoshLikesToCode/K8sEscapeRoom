#!/usr/bin/env bash
# reset-hook.sh - Clean up cluster-scoped resources created while solving this room
# The fix for this room creates a "fast-storage" StorageClass, which is cluster-scoped
# and doesn't get deleted when the namespace is removed.
kubectl delete storageclass fast-storage 2>/dev/null || true
