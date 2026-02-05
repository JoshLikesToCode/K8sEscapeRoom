#!/usr/bin/env bash
# room-test.sh - Run tests for a room with retry logic for async pod states
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

ROOM_NAME="${1:-}"

# Configuration
MAX_WAIT_SECONDS="${MAX_WAIT_SECONDS:-60}"
POLL_INTERVAL="${POLL_INTERVAL:-5}"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
CYAN='\033[0;36m'
DIM='\033[2m'
NC='\033[0m'

#######################################
# Print error and exit
#######################################
die() {
    echo -e "${RED}Error: $1${NC}" >&2
    exit 1
}

#######################################
# Print current pod status for debugging
#######################################
print_pod_status() {
    local namespace="$1"
    echo ""
    echo -e "${YELLOW}Current pod status:${NC}"
    echo -e "${DIM}────────────────────────────────────────${NC}"
    kubectl get pods -n "$namespace" -o wide 2>/dev/null || echo "  (no pods found)"
    echo -e "${DIM}────────────────────────────────────────${NC}"
    echo ""
    echo -e "${YELLOW}Recent events:${NC}"
    echo -e "${DIM}────────────────────────────────────────${NC}"
    kubectl get events -n "$namespace" --sort-by='.lastTimestamp' 2>/dev/null | tail -10 || echo "  (no events)"
    echo -e "${DIM}────────────────────────────────────────${NC}"
}

#######################################
# Wait for any pod to exist in namespace
#######################################
wait_for_any_pod() {
    local namespace="$1"
    local timeout="$2"

    local elapsed=0
    echo -n "Waiting for pods to exist in namespace"

    while [ $elapsed -lt "$timeout" ]; do
        if kubectl get pods -n "$namespace" --no-headers 2>/dev/null | grep -q .; then
            echo -e " ${GREEN}found${NC}"
            return 0
        fi
        echo -n "."
        sleep "$POLL_INTERVAL"
        elapsed=$((elapsed + POLL_INTERVAL))
    done

    echo -e " ${RED}timeout${NC}"
    return 1
}

#######################################
# Run tests with retry logic
#######################################
run_tests_with_retry() {
    local test_file="$1"
    local namespace="$2"
    local timeout="$3"

    local elapsed=0
    local attempt=1
    local last_error=""

    echo -e "${CYAN}Running tests with ${timeout}s timeout...${NC}"
    echo ""

    while [ $elapsed -lt "$timeout" ]; do
        echo -e "${DIM}[Attempt $attempt @ ${elapsed}s]${NC}"

        # Capture test output and exit code
        set +e
        test_output=$(NAMESPACE="$namespace" bash "$test_file" 2>&1)
        test_exit_code=$?
        set -e

        if [ $test_exit_code -eq 0 ]; then
            echo "$test_output"
            return 0
        fi

        last_error="$test_output"

        # Check if this is a "not ready yet" situation vs a real failure
        if echo "$test_output" | grep -qiE "(not found|does not exist|no pods|waiting)"; then
            echo -e "  ${YELLOW}Pod not ready yet, retrying...${NC}"
        else
            # Show incremental test output for visibility
            echo "$test_output" | head -5
            if [ "$(echo "$test_output" | wc -l)" -gt 5 ]; then
                echo -e "  ${DIM}... (truncated, will show full output on final attempt)${NC}"
            fi
        fi

        sleep "$POLL_INTERVAL"
        elapsed=$((elapsed + POLL_INTERVAL))
        attempt=$((attempt + 1))
    done

    # Final failure - show everything
    echo ""
    echo -e "${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${RED}Tests failed after ${timeout}s${NC}"
    echo -e "${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    echo -e "${YELLOW}Last test output:${NC}"
    echo -e "${DIM}────────────────────────────────────────${NC}"
    echo "$last_error"
    echo -e "${DIM}────────────────────────────────────────${NC}"

    print_pod_status "$namespace"

    return 1
}

#######################################
# Main
#######################################

if [ -z "$ROOM_NAME" ]; then
    echo -e "${RED}Error: Room name required${NC}"
    echo ""
    echo "Usage: $0 <room-name>"
    echo ""
    echo "Environment variables:"
    echo "  MAX_WAIT_SECONDS  Timeout for tests (default: 60)"
    echo "  POLL_INTERVAL     Seconds between retries (default: 5)"
    exit 1
fi

ROOM_DIR="${PROJECT_ROOT}/rooms/${ROOM_NAME}"
TEST_FILE="${ROOM_DIR}/tests.sh"
NAMESPACE="escape-${ROOM_NAME}"

# Validate room exists
if [ ! -d "$ROOM_DIR" ]; then
    die "Room '${ROOM_NAME}' not found"
fi

# Validate test file exists and is executable
if [ ! -f "$TEST_FILE" ]; then
    die "No tests.sh found for room '${ROOM_NAME}'"
fi

if [ ! -x "$TEST_FILE" ]; then
    die "tests.sh is not executable. Fix with: chmod +x $TEST_FILE"
fi

# Check namespace exists (room must be applied first)
if ! kubectl get namespace "$NAMESPACE" >/dev/null 2>&1; then
    echo -e "${RED}Error: Namespace '$NAMESPACE' does not exist${NC}"
    echo ""
    echo "Did you forget to apply the room first?"
    echo ""
    echo "Run:"
    echo -e "  ${GREEN}make room-apply ROOM=$ROOM_NAME${NC}"
    exit 1
fi

echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${CYAN}Testing room: ${ROOM_NAME}${NC}"
echo -e "${CYAN}Namespace: ${NAMESPACE}${NC}"
echo -e "${CYAN}Timeout: ${MAX_WAIT_SECONDS}s${NC}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

# Wait for any pod to exist first
if ! wait_for_any_pod "$NAMESPACE" "$MAX_WAIT_SECONDS"; then
    echo -e "${RED}Error: No pods appeared in namespace${NC}"
    print_pod_status "$NAMESPACE"
    exit 1
fi

# Run tests with retry logic
if run_tests_with_retry "$TEST_FILE" "$NAMESPACE" "$MAX_WAIT_SECONDS"; then
    echo ""
    echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${GREEN}All tests passed for room '${ROOM_NAME}'${NC}"
    echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    exit 0
else
    exit 1
fi
