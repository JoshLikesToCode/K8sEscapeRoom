#!/usr/bin/env bash
# tests.sh - Validate room-pending-resources is in expected failure state
#
# Expected state: Pod stuck in Pending due to excessive resource requests
#
# Success criteria:
#   - Pod exists
#   - Pod is in Pending phase (not scheduled)
#   - Events mention insufficient resources
#   - Resource requests are excessive (64Gi memory, 32 CPU)
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../../scripts/test-helpers.sh"

# Configuration
NAMESPACE="${NAMESPACE:-escape-room-pending-resources}"
POD_NAME="escape-app"
ROOM_NAME="room-pending-resources"
EXPECTED_MEMORY="64Gi"
EXPECTED_CPU="32"

echo -e "${CYAN}Testing room: ${ROOM_NAME}${NC}"
echo -e "${DIM}Namespace: ${NAMESPACE}${NC}"
echo -e "${DIM}Expected: Pending (insufficient resources)${NC}"
echo ""

# ============================================================================
# Test 1: Pod exists
# ============================================================================
test_start "Pod '$POD_NAME' exists"

if assert_pod_exists "$POD_NAME" "$NAMESPACE"; then
    test_pass
else
    test_fail "Pod '$POD_NAME' does not exist in namespace '$NAMESPACE'"
fi

# ============================================================================
# Test 2: Pod is in Pending phase
# ============================================================================
test_start "Pod is in Pending phase"

pod_phase=$(get_pod_phase "$POD_NAME" "$NAMESPACE")

if [ "$pod_phase" = "Pending" ]; then
    test_pass
elif [ "$pod_phase" = "Running" ]; then
    dump_debug_info "$NAMESPACE"
    test_fail "Pod is Running - expected Pending (unschedulable)"
else
    test_warn "Unexpected phase: $pod_phase"
fi

# ============================================================================
# Test 3: Events mention scheduling failure
# ============================================================================
test_start "Events show FailedScheduling with resource issue"

# Look for various resource-related scheduling failures
if assert_event_contains "$NAMESPACE" "(Insufficient memory|Insufficient cpu|FailedScheduling|nodes are available)"; then
    # Get the actual message for display
    event_msg=$(kubectl get events -n "$NAMESPACE" --sort-by='.lastTimestamp' \
        -o jsonpath='{.items[*].message}' 2>/dev/null | tr ' ' '\n' | grep -iE "(insufficient|failed)" | head -1 || echo "")
    if [ -n "$event_msg" ]; then
        test_pass "FailedScheduling detected"
    else
        test_pass
    fi
else
    test_warn "Could not find resource-related scheduling failure in events"
fi

# ============================================================================
# Test 4: Resource requests are excessive
# ============================================================================
test_start "Memory request is $EXPECTED_MEMORY"

actual_memory=$(kubectl get pod "$POD_NAME" -n "$NAMESPACE" \
    -o jsonpath='{.spec.containers[0].resources.requests.memory}' 2>/dev/null || echo "")

if [ "$actual_memory" = "$EXPECTED_MEMORY" ]; then
    test_pass
else
    if [ -n "$actual_memory" ]; then
        dump_debug_info "$NAMESPACE"
        test_fail "Memory request is '$actual_memory' - expected '$EXPECTED_MEMORY'"
    else
        test_warn "Could not determine memory request"
    fi
fi

# ============================================================================
# Test 5: CPU requests are excessive
# ============================================================================
test_start "CPU request is $EXPECTED_CPU"

actual_cpu=$(kubectl get pod "$POD_NAME" -n "$NAMESPACE" \
    -o jsonpath='{.spec.containers[0].resources.requests.cpu}' 2>/dev/null || echo "")

if [ "$actual_cpu" = "$EXPECTED_CPU" ]; then
    test_pass
else
    if [ -n "$actual_cpu" ]; then
        dump_debug_info "$NAMESPACE"
        test_fail "CPU request is '$actual_cpu' - expected '$EXPECTED_CPU'"
    else
        test_warn "Could not determine CPU request"
    fi
fi

# ============================================================================
# Test 6: Pod has no node assigned (confirming it's unscheduled)
# ============================================================================
test_start "Pod has no node assigned"

node_name=$(kubectl get pod "$POD_NAME" -n "$NAMESPACE" \
    -o jsonpath='{.spec.nodeName}' 2>/dev/null || echo "")

if [ -z "$node_name" ]; then
    test_pass "no nodeName set"
else
    dump_debug_info "$NAMESPACE"
    test_fail "Pod is assigned to node '$node_name' - should be unschedulable"
fi

# ============================================================================
# Summary
# ============================================================================
finish_tests
