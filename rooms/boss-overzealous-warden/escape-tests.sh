#!/usr/bin/env bash
# escape-tests.sh - Validate boss-overzealous-warden has been ESCAPED (fixed)
#
# Success criteria (ALL must pass):
#   - Pod is Running and Ready (1/1)
#   - runAsNonRoot is still true (didn't just remove security)
#   - runAsUser is set to a non-zero value
#   - readOnlyRootFilesystem is still true (didn't just remove it)
#   - Writable /tmp volume exists

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../../scripts/test-helpers.sh"

NAMESPACE="escape-boss-overzealous-warden"
DEPLOYMENT_NAME="escape-app"
POD_LABEL="app=escape-app"

echo "=== Testing boss-overzealous-warden (escaped/fixed state) ==="
echo ""

# ============================================================================
# Test 1: Pod is Running
# ============================================================================
test_start "Pod is Running"

RUNNING_COUNT=$(kubectl get pods -n "$NAMESPACE" -l "$POD_LABEL" --no-headers 2>/dev/null | grep -c "Running" || true)

if [ "$RUNNING_COUNT" -gt 0 ]; then
    test_pass "$RUNNING_COUNT pod(s) Running"
else
    test_fail "No pods in Running state"
fi

# ============================================================================
# Test 2: Pod is Ready (1/1)
# ============================================================================
test_start "Pod is Ready (1/1)"

READY_PODS=$(kubectl get pods -n "$NAMESPACE" -l "$POD_LABEL" --no-headers 2>/dev/null | grep -c "1/1" || true)

if [ "$READY_PODS" -gt 0 ]; then
    test_pass "$READY_PODS pod(s) Ready"
else
    test_fail "No pods are Ready — check security context and volumes"
fi

# ============================================================================
# Test 3: runAsNonRoot is still true (security preserved)
# ============================================================================
test_start "runAsNonRoot is still true (security preserved)"

RUN_AS_NON_ROOT=$(kubectl get deployment "$DEPLOYMENT_NAME" -n "$NAMESPACE" \
    -o jsonpath='{.spec.template.spec.containers[0].securityContext.runAsNonRoot}' 2>/dev/null || echo "")

if [ "$RUN_AS_NON_ROOT" = "true" ]; then
    test_pass "runAsNonRoot: true"
else
    test_fail "runAsNonRoot is '$RUN_AS_NON_ROOT' — you can't just remove the security setting!"
fi

# ============================================================================
# Test 4: runAsUser is set to a non-zero value
# ============================================================================
test_start "runAsUser is set to a non-root value"

RUN_AS_USER=$(kubectl get deployment "$DEPLOYMENT_NAME" -n "$NAMESPACE" \
    -o jsonpath='{.spec.template.spec.containers[0].securityContext.runAsUser}' 2>/dev/null || echo "")

if [ -n "$RUN_AS_USER" ] && [ "$RUN_AS_USER" -ne 0 ] 2>/dev/null; then
    test_pass "runAsUser: $RUN_AS_USER"
else
    test_fail "runAsUser is '${RUN_AS_USER:-not set}' — must be set to a non-zero UID"
fi

# ============================================================================
# Test 5: readOnlyRootFilesystem is still true (security preserved)
# ============================================================================
test_start "readOnlyRootFilesystem is still true (security preserved)"

READ_ONLY=$(kubectl get deployment "$DEPLOYMENT_NAME" -n "$NAMESPACE" \
    -o jsonpath='{.spec.template.spec.containers[0].securityContext.readOnlyRootFilesystem}' 2>/dev/null || echo "")

if [ "$READ_ONLY" = "true" ]; then
    test_pass "readOnlyRootFilesystem: true"
else
    test_fail "readOnlyRootFilesystem is '$READ_ONLY' — you can't just remove the security setting!"
fi

# ============================================================================
# Test 6: Writable /tmp volume exists
# ============================================================================
test_start "Writable /tmp volume mounted"

VOLUME_MOUNTS=$(kubectl get deployment "$DEPLOYMENT_NAME" -n "$NAMESPACE" \
    -o jsonpath='{.spec.template.spec.containers[0].volumeMounts[*].mountPath}' 2>/dev/null || echo "")

if echo "$VOLUME_MOUNTS" | grep -q "/tmp"; then
    test_pass "/tmp volume mount found"
else
    test_fail "No writable volume at /tmp — nginx needs this for pid, cache, and temp files"
fi

echo ""
echo -e "${GREEN}=========================================="
echo "  CONGRATULATIONS! You escaped the boss room!"
echo "==========================================${NC}"
echo ""
echo "You successfully fixed BOTH issues:"
echo "  1. Added runAsUser to satisfy runAsNonRoot"
echo "  2. Added an emptyDir volume at /tmp for nginx's writable files"
echo ""
echo "Security settings were preserved — well done!"
echo ""
