#!/usr/bin/env bash
# escape-tests.sh - Validate boss-slow-death has been ESCAPED (fixed)
#
# Success criteria (ALL must pass):
#   - Pod is Running and Ready
#   - Pod is stable (no new restarts)
#   - Memory limit is adequate (>= 64Mi)
#   - Probe configuration is reasonable

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../../scripts/test-helpers.sh"

NAMESPACE="escape-boss-slow-death"
POD_NAME="escape-app"

echo "=== Testing boss-slow-death (escaped/fixed state) ==="
echo ""

# ============================================================================
# Test 1: Pod is Running
# ============================================================================
test_start "Pod is Running"

PHASE=$(get_pod_phase "$POD_NAME" "$NAMESPACE")

if [ "$PHASE" = "Running" ]; then
    test_pass "$PHASE"
else
    test_fail "Pod is in '$PHASE' state, expected 'Running'"
fi

# ============================================================================
# Test 2: Pod is Ready
# ============================================================================
test_start "Pod is Ready"

READY=$(kubectl get pod "$POD_NAME" -n "$NAMESPACE" \
    -o jsonpath='{.status.conditions[?(@.type=="Ready")].status}' 2>/dev/null || echo "False")

if [ "$READY" = "True" ]; then
    test_pass
else
    test_fail "Pod is not Ready"
fi

# ============================================================================
# Test 3: Pod is stable (no new restarts)
# ============================================================================
test_start "Pod is stable (no new restarts)"

RESTARTS_BEFORE=$(get_restart_count "$POD_NAME" "$NAMESPACE")
echo -n "(waiting 15s to verify stability)... "
sleep 15
RESTARTS_AFTER=$(get_restart_count "$POD_NAME" "$NAMESPACE")

if [ "$RESTARTS_BEFORE" = "$RESTARTS_AFTER" ]; then
    test_pass "Restart count stable at $RESTARTS_AFTER"
else
    test_fail "Restart count increased from $RESTARTS_BEFORE to $RESTARTS_AFTER"
fi

# ============================================================================
# Test 4: Memory limit is adequate
# ============================================================================
test_start "Memory limit is adequate (>= 64Mi)"

MEMORY_LIMIT=$(kubectl get pod "$POD_NAME" -n "$NAMESPACE" \
    -o jsonpath='{.spec.containers[0].resources.limits.memory}' 2>/dev/null || echo "")

# Extract numeric value
MEMORY_VALUE="${MEMORY_LIMIT%Mi}"

if [ -n "$MEMORY_VALUE" ] && [ "$MEMORY_VALUE" -ge 64 ] 2>/dev/null; then
    test_pass "Memory limit is ${MEMORY_LIMIT}"
else
    test_warn "Memory limit is ${MEMORY_LIMIT} - recommend >= 64Mi"
fi

# ============================================================================
# Test 5: Probe configuration is reasonable
# ============================================================================
test_start "Liveness probe failureThreshold >= 2"

FAILURE_THRESHOLD=$(kubectl get pod "$POD_NAME" -n "$NAMESPACE" \
    -o jsonpath='{.spec.containers[0].livenessProbe.failureThreshold}' 2>/dev/null || echo "0")

if [ -z "$FAILURE_THRESHOLD" ] || [ "$FAILURE_THRESHOLD" = "0" ]; then
    test_pass "Liveness probe removed"
elif [ "$FAILURE_THRESHOLD" -ge 2 ]; then
    test_pass "failureThreshold=$FAILURE_THRESHOLD"
else
    test_warn "failureThreshold=$FAILURE_THRESHOLD - recommend >= 2"
fi

echo ""
echo -e "${GREEN}=========================================="
echo "  CONGRATULATIONS! You escaped the boss room!"
echo "==========================================${NC}"
echo ""
echo "You successfully fixed BOTH resource issues:"
echo "  1. Increased memory limit to prevent OOMKilled"
echo "  2. Made liveness probe more lenient"
echo ""
echo "The slow death has been prevented!"
echo ""
