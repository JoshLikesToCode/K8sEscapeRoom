#!/usr/bin/env bash
# test-helpers.sh - Shared test utilities for K8sEscapeRoom room tests
#
# Usage: source this file at the top of your tests.sh
#   source "$(dirname "$0")/../../scripts/test-helpers.sh"
#
# Provides:
#   - Color constants (RED, GREEN, YELLOW, CYAN, DIM, NC)
#   - test_start <test_name>           - Start a test (prints "Test N: <name>...")
#   - test_pass [message]              - Mark test as passed
#   - test_fail <message>              - Mark test as failed and exit
#   - test_warn <message>              - Mark test with warning (non-fatal)
#   - test_skip <message>              - Skip test
#   - assert_pod_exists <pod> <ns>     - Assert pod exists
#   - assert_pod_phase <pod> <ns> <phase>  - Assert pod is in specific phase
#   - assert_waiting_reason <pod> <ns> <reason>  - Assert container waiting reason
#   - assert_event_contains <ns> <pattern>  - Assert events contain pattern
#   - get_pod_phase <pod> <ns>         - Get pod phase
#   - get_waiting_reason <pod> <ns>    - Get container waiting reason
#   - get_restart_count <pod> <ns>     - Get container restart count
#   - get_pod_logs <pod> <ns>          - Get pod logs (current or previous)
#   - dump_debug_info <ns>             - Dump pods, events, describe for debugging
#   - finish_tests                     - Print summary and exit appropriately

set -euo pipefail

# ============================================================================
# Colors
# ============================================================================
export RED='\033[0;31m'
export GREEN='\033[0;32m'
export YELLOW='\033[0;33m'
export CYAN='\033[0;36m'
export DIM='\033[2m'
export BOLD='\033[1m'
export NC='\033[0m'

# ============================================================================
# Test State
# ============================================================================
_TEST_COUNT=0
_TEST_PASSED=0
_TEST_FAILED=0
_TEST_WARNED=0
_CURRENT_TEST=""

# ============================================================================
# Test Framework Functions
# ============================================================================

# Start a new test
# Usage: test_start "Pod exists"
test_start() {
    local test_name="$1"
    _TEST_COUNT=$((_TEST_COUNT + 1))
    _CURRENT_TEST="$test_name"
    echo -n "Test $_TEST_COUNT: $test_name... "
}

# Mark current test as passed
# Usage: test_pass or test_pass "CrashLoopBackOff detected"
test_pass() {
    local message="${1:-}"
    _TEST_PASSED=$((_TEST_PASSED + 1))
    if [ -n "$message" ]; then
        echo -e "${GREEN}PASS${NC} ($message)"
    else
        echo -e "${GREEN}PASS${NC}"
    fi
}

# Mark current test as failed and exit
# Usage: test_fail "Pod not found"
test_fail() {
    local message="$1"
    _TEST_FAILED=$((_TEST_FAILED + 1))
    echo -e "${RED}FAIL${NC}"
    echo -e "${RED}  → $message${NC}"
    exit 1
}

# Mark current test with warning (non-fatal)
# Usage: test_warn "Could not verify logs"
test_warn() {
    local message="$1"
    _TEST_WARNED=$((_TEST_WARNED + 1))
    echo -e "${YELLOW}WARN${NC} ($message)"
}

# Skip current test
# Usage: test_skip "Not applicable for this room"
test_skip() {
    local message="$1"
    echo -e "${DIM}SKIP${NC} ($message)"
}

# ============================================================================
# Kubectl Helper Functions
# ============================================================================

# Get pod phase (Pending, Running, Succeeded, Failed, Unknown)
get_pod_phase() {
    local pod="$1"
    local namespace="$2"
    kubectl get pod "$pod" -n "$namespace" -o jsonpath='{.status.phase}' 2>/dev/null || echo ""
}

# Get container waiting reason (CrashLoopBackOff, ImagePullBackOff, etc.)
get_waiting_reason() {
    local pod="$1"
    local namespace="$2"
    kubectl get pod "$pod" -n "$namespace" \
        -o jsonpath='{.status.containerStatuses[0].state.waiting.reason}' 2>/dev/null || echo ""
}

# Get container terminated reason
get_terminated_reason() {
    local pod="$1"
    local namespace="$2"
    kubectl get pod "$pod" -n "$namespace" \
        -o jsonpath='{.status.containerStatuses[0].state.terminated.reason}' 2>/dev/null || echo ""
}

# Get container restart count
get_restart_count() {
    local pod="$1"
    local namespace="$2"
    kubectl get pod "$pod" -n "$namespace" \
        -o jsonpath='{.status.containerStatuses[0].restartCount}' 2>/dev/null || echo "0"
}

# Get full container state as JSON
get_container_state() {
    local pod="$1"
    local namespace="$2"
    kubectl get pod "$pod" -n "$namespace" \
        -o jsonpath='{.status.containerStatuses[0].state}' 2>/dev/null || echo "{}"
}

# Get pod logs (tries current first, then previous)
get_pod_logs() {
    local pod="$1"
    local namespace="$2"
    # Try current logs first, then previous (for crashed containers)
    kubectl logs "$pod" -n "$namespace" 2>/dev/null || \
        kubectl logs "$pod" -n "$namespace" --previous 2>/dev/null || \
        echo ""
}

# Get pod events
get_pod_events() {
    local pod="$1"
    local namespace="$2"
    kubectl get events -n "$namespace" \
        --field-selector "involvedObject.name=$pod" \
        --sort-by='.lastTimestamp' 2>/dev/null || echo ""
}

# Get namespace events
get_namespace_events() {
    local namespace="$1"
    kubectl get events -n "$namespace" --sort-by='.lastTimestamp' 2>/dev/null || echo ""
}

# ============================================================================
# Assertion Functions
# ============================================================================

# Assert pod exists
# Usage: assert_pod_exists "escape-app" "$NAMESPACE"
assert_pod_exists() {
    local pod="$1"
    local namespace="$2"

    if kubectl get pod "$pod" -n "$namespace" &>/dev/null; then
        return 0
    else
        return 1
    fi
}

# Assert pod is in specific phase
# Usage: assert_pod_phase "escape-app" "$NAMESPACE" "Pending"
assert_pod_phase() {
    local pod="$1"
    local namespace="$2"
    local expected_phase="$3"

    local actual_phase
    actual_phase=$(get_pod_phase "$pod" "$namespace")

    if [ "$actual_phase" = "$expected_phase" ]; then
        return 0
    else
        return 1
    fi
}

# Assert container is in waiting state with specific reason
# Usage: assert_waiting_reason "escape-app" "$NAMESPACE" "CrashLoopBackOff"
assert_waiting_reason() {
    local pod="$1"
    local namespace="$2"
    local expected_reason="$3"

    local actual_reason
    actual_reason=$(get_waiting_reason "$pod" "$namespace")

    if [ "$actual_reason" = "$expected_reason" ]; then
        return 0
    else
        return 1
    fi
}

# Assert events contain a pattern
# Usage: assert_event_contains "$NAMESPACE" "Insufficient memory"
assert_event_contains() {
    local namespace="$1"
    local pattern="$2"

    local events
    events=$(get_namespace_events "$namespace")

    if echo "$events" | grep -qE "$pattern"; then
        return 0
    else
        return 1
    fi
}

# Assert logs contain a pattern
# Usage: assert_logs_contain "escape-app" "$NAMESPACE" "DATABASE_URL"
assert_logs_contain() {
    local pod="$1"
    local namespace="$2"
    local pattern="$3"

    local logs
    logs=$(get_pod_logs "$pod" "$namespace")

    if echo "$logs" | grep -q "$pattern"; then
        return 0
    else
        return 1
    fi
}

# ============================================================================
# Debug Functions
# ============================================================================

# Dump debug info for a namespace (call on failure)
dump_debug_info() {
    local namespace="$1"

    echo ""
    echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${YELLOW}DEBUG INFO${NC}"
    echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

    echo ""
    echo -e "${CYAN}Pods:${NC}"
    echo -e "${DIM}────────────────────────────────────────${NC}"
    kubectl get pods -n "$namespace" -o wide 2>/dev/null || echo "  (no pods)"

    echo ""
    echo -e "${CYAN}Events (last 15):${NC}"
    echo -e "${DIM}────────────────────────────────────────${NC}"
    kubectl get events -n "$namespace" --sort-by='.lastTimestamp' 2>/dev/null | tail -15 || echo "  (no events)"

    echo ""
    echo -e "${CYAN}Pod Description:${NC}"
    echo -e "${DIM}────────────────────────────────────────${NC}"
    kubectl describe pods -n "$namespace" 2>/dev/null | tail -40 || echo "  (no pods to describe)"

    echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
}

# ============================================================================
# Test Summary
# ============================================================================

# Print test summary and exit with appropriate code
finish_tests() {
    echo ""
    if [ $_TEST_FAILED -eq 0 ]; then
        echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        echo -e "${GREEN}All $_TEST_PASSED tests passed!${NC}"
        if [ $_TEST_WARNED -gt 0 ]; then
            echo -e "${YELLOW}($_TEST_WARNED warnings)${NC}"
        fi
        echo -e "${GREEN}Room is in expected failure state.${NC}"
        echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        exit 0
    else
        echo -e "${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        echo -e "${RED}$_TEST_FAILED of $_TEST_COUNT tests failed${NC}"
        echo -e "${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        exit 1
    fi
}
