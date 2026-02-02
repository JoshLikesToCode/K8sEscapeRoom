#!/usr/bin/env bash
# room-new.sh - Scaffold a new escape room
#
# Usage: ./scripts/room-new.sh <room-name>
#
# Creates the standard room structure with template files.

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
ROOMS_DIR="$PROJECT_ROOT/rooms"

usage() {
    echo "Usage: $0 <room-name>"
    echo ""
    echo "Room name should follow the pattern: room-<description>"
    echo "Example: $0 room-oom-killed"
    echo ""
    echo "This will create:"
    echo "  rooms/<room-name>/"
    echo "    app.yaml"
    echo "    tests.sh"
    echo "    escape-tests.sh"
    echo "    OBJECTIVE.md"
    echo "    HINTS.md"
    echo "    SOLUTION.md"
    exit 1
}

# Validate arguments
if [[ $# -ne 1 ]]; then
    usage
fi

ROOM_NAME="$1"

# Validate room name format
if [[ ! "$ROOM_NAME" =~ ^room-[a-z0-9-]+$ ]]; then
    echo -e "${RED}Error: Room name must match pattern 'room-<description>'${NC}"
    echo "Use lowercase letters, numbers, and hyphens only."
    echo "Example: room-oom-killed, room-service-not-found"
    exit 1
fi

ROOM_DIR="$ROOMS_DIR/$ROOM_NAME"

# Check if room already exists
if [[ -d "$ROOM_DIR" ]]; then
    echo -e "${RED}Error: Room '$ROOM_NAME' already exists at $ROOM_DIR${NC}"
    exit 1
fi

echo -e "${CYAN}Creating new escape room: $ROOM_NAME${NC}"
echo ""

# Create directory structure
mkdir -p "$ROOM_DIR"

# Extract a readable title from room name (room-foo-bar -> Foo Bar)
ROOM_TITLE=$(echo "$ROOM_NAME" | sed 's/^room-//' | sed 's/-/ /g' | sed 's/\b\(.\)/\u\1/g')

# Create namespace name
NAMESPACE="escape-$ROOM_NAME"

# =============================================================================
# Create app.yaml
# =============================================================================
cat > "$ROOM_DIR/app.yaml" << 'MANIFEST_EOF'
# K8sEscapeRoom - ROOM_NAME_PLACEHOLDER
# This manifest creates a deliberately broken deployment for debugging practice.
#
# The failure mode: [DESCRIBE THE FAILURE HERE]
#
apiVersion: v1
kind: Namespace
metadata:
  name: NAMESPACE_PLACEHOLDER
  labels:
    app.kubernetes.io/name: escape-app
    app.kubernetes.io/part-of: k8s-escape-room
    app.kubernetes.io/component: ROOM_NAME_PLACEHOLDER
    k8sescaperoom.dev/room: ROOM_NAME_PLACEHOLDER
    k8sescaperoom.dev/difficulty: beginner
    k8sescaperoom.dev/category: [configuration|networking|resources|scheduling]
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: escape-app
  namespace: NAMESPACE_PLACEHOLDER
  labels:
    app.kubernetes.io/name: escape-app
    app.kubernetes.io/part-of: k8s-escape-room
    app.kubernetes.io/component: ROOM_NAME_PLACEHOLDER
    k8sescaperoom.dev/room: ROOM_NAME_PLACEHOLDER
spec:
  replicas: 1
  selector:
    matchLabels:
      app: escape-app
  template:
    metadata:
      labels:
        app: escape-app
        app.kubernetes.io/name: escape-app
        k8sescaperoom.dev/room: ROOM_NAME_PLACEHOLDER
    spec:
      containers:
        - name: app
          image: busybox:1.36
          command:
            - /bin/sh
            - -c
            - |
              # TODO: Add your failure simulation here
              echo "Application starting..."
              # Example: exit 1 to crash, or sleep to stay running
              while true; do sleep 3600; done
          resources:
            requests:
              memory: "64Mi"
              cpu: "100m"
            limits:
              memory: "128Mi"
              cpu: "200m"
MANIFEST_EOF

# Replace placeholders
sed -i "s/ROOM_NAME_PLACEHOLDER/$ROOM_NAME/g" "$ROOM_DIR/app.yaml"
sed -i "s/NAMESPACE_PLACEHOLDER/$NAMESPACE/g" "$ROOM_DIR/app.yaml"

# =============================================================================
# Create tests.sh (validates broken state)
# =============================================================================
cat > "$ROOM_DIR/tests.sh" << 'TESTS_EOF'
#!/usr/bin/env bash
# tests.sh - Validate that the room is in the expected BROKEN state
#
# This script runs BEFORE the user attempts to fix anything.
# It should verify the failure condition is present.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../../scripts/test-helpers.sh"

NAMESPACE="NAMESPACE_PLACEHOLDER"
POD_LABEL="app=escape-app"

echo "=== Testing ROOM_NAME_PLACEHOLDER (broken state) ==="
echo ""

# Wait for pod to exist
test_start "Pod exists in namespace"
if wait_for_pod "$NAMESPACE" "$POD_LABEL"; then
    test_pass "Pod found"
else
    test_fail "Pod not found in namespace $NAMESPACE"
    exit 1
fi

# TODO: Add your specific failure state checks here
# Example for CrashLoopBackOff:
# test_start "Pod is in CrashLoopBackOff"
# REASON=$(get_waiting_reason "$NAMESPACE" "$POD_LABEL")
# if [[ "$REASON" == "CrashLoopBackOff" ]]; then
#     test_pass "Pod is in CrashLoopBackOff as expected"
# else
#     test_fail "Expected CrashLoopBackOff, got: $REASON"
#     dump_debug_info "$NAMESPACE"
#     exit 1
# fi

test_start "Pod is in expected failure state"
# TODO: Replace with actual check
test_fail "TODO: Implement failure state check"
exit 1

echo ""
echo "=== All broken-state tests passed ==="
TESTS_EOF

# Replace placeholders
sed -i "s/ROOM_NAME_PLACEHOLDER/$ROOM_NAME/g" "$ROOM_DIR/tests.sh"
sed -i "s/NAMESPACE_PLACEHOLDER/$NAMESPACE/g" "$ROOM_DIR/tests.sh"
chmod +x "$ROOM_DIR/tests.sh"

# =============================================================================
# Create escape-tests.sh (validates fixed state)
# =============================================================================
cat > "$ROOM_DIR/escape-tests.sh" << 'ESCAPE_TESTS_EOF'
#!/usr/bin/env bash
# escape-tests.sh - Validate that the room has been ESCAPED (fixed)
#
# This script runs AFTER the user attempts to fix the issue.
# It should verify the application is now working correctly.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../../scripts/test-helpers.sh"

NAMESPACE="NAMESPACE_PLACEHOLDER"
POD_LABEL="app=escape-app"

echo "=== Testing ROOM_NAME_PLACEHOLDER (escaped/fixed state) ==="
echo ""

# Check pod is running
test_start "Pod is Running"
if wait_for_condition "$NAMESPACE" "$POD_LABEL" "Ready" "True" 30; then
    test_pass "Pod is Running and Ready"
else
    test_fail "Pod is not in Running/Ready state"
    dump_debug_info "$NAMESPACE"
    exit 1
fi

# Check pod hasn't restarted recently (stable for 30s)
test_start "Pod is stable (no recent restarts)"
POD_NAME=$(kubectl get pods -n "$NAMESPACE" -l "$POD_LABEL" -o jsonpath='{.items[0].metadata.name}' 2>/dev/null)
RESTARTS=$(kubectl get pod "$POD_NAME" -n "$NAMESPACE" -o jsonpath='{.status.containerStatuses[0].restartCount}' 2>/dev/null || echo "0")

# Wait a bit and check restarts again
sleep 5
RESTARTS_AFTER=$(kubectl get pod "$POD_NAME" -n "$NAMESPACE" -o jsonpath='{.status.containerStatuses[0].restartCount}' 2>/dev/null || echo "0")

if [[ "$RESTARTS" == "$RESTARTS_AFTER" ]]; then
    test_pass "Pod is stable (restart count: $RESTARTS)"
else
    test_fail "Pod is still restarting (was $RESTARTS, now $RESTARTS_AFTER)"
    exit 1
fi

# TODO: Add any room-specific success checks here
# Example: check logs for success message
# test_start "Application shows success message"
# if kubectl logs "$POD_NAME" -n "$NAMESPACE" | grep -q "Application started successfully"; then
#     test_pass "Success message found in logs"
# else
#     test_fail "Success message not found"
#     exit 1
# fi

echo ""
echo "=========================================="
echo "  CONGRATULATIONS! You escaped the room!"
echo "=========================================="
echo ""
ESCAPE_TESTS_EOF

# Replace placeholders
sed -i "s/ROOM_NAME_PLACEHOLDER/$ROOM_NAME/g" "$ROOM_DIR/escape-tests.sh"
sed -i "s/NAMESPACE_PLACEHOLDER/$NAMESPACE/g" "$ROOM_DIR/escape-tests.sh"
chmod +x "$ROOM_DIR/escape-tests.sh"

# =============================================================================
# Create OBJECTIVE.md
# =============================================================================
cat > "$ROOM_DIR/OBJECTIVE.md" << OBJECTIVE_EOF
# Escape Room: $ROOM_TITLE

[One-line description of what's broken]

## Your Mission

1. Identify why the pod is failing
2. Determine the root cause
3. Fix the issue so the pod runs successfully

## Success Criteria

- The pod \`escape-app\` is in \`Running\` state
- The pod has been running for at least 30 seconds without restarting

## Getting Started

\`\`\`bash
# Check the pod status
kubectl get pods -n $NAMESPACE

# Describe the pod for more details
kubectl describe pod -l app=escape-app -n $NAMESPACE

# Check the logs
kubectl logs -l app=escape-app -n $NAMESPACE
\`\`\`

## Validate Your Fix

\`\`\`bash
make room-escape-test ROOM=$ROOM_NAME
\`\`\`
OBJECTIVE_EOF

# =============================================================================
# Create HINTS.md
# =============================================================================
cat > "$ROOM_DIR/HINTS.md" << HINTS_EOF
# Hints for $ROOM_TITLE

Use these hints progressively if you get stuck. Try to solve it with as few hints as possible!

---

## Hint Level 1: Where to Look

[General direction - what commands to run, what to inspect]

**Useful commands:**
\`\`\`bash
kubectl get pods -n $NAMESPACE
kubectl describe pod -l app=escape-app -n $NAMESPACE
\`\`\`

---

## Hint Level 2: What to Look For

[More specific - what section of output, what error pattern]

---

## Hint Level 3: The Root Cause

[Explain what's actually wrong without giving the fix]

---

## Hint Level 4: The Fix

[Exact steps to fix, without full commands]

---
HINTS_EOF

# =============================================================================
# Create SOLUTION.md
# =============================================================================
cat > "$ROOM_DIR/SOLUTION.md" << SOLUTION_EOF
# Solution: $ROOM_TITLE

> **SPOILER WARNING**: Only read this after attempting to solve the room yourself!

## The Problem

[Explain what was broken and why]

## The Diagnosis

[Show the debugging steps that reveal the issue]

\`\`\`bash
# Step 1: Check pod status
kubectl get pods -n $NAMESPACE

# Step 2: Look at events/logs
kubectl describe pod -l app=escape-app -n $NAMESPACE
\`\`\`

## The Fix

[Explain the fix conceptually]

\`\`\`bash
# The command(s) to fix it
kubectl [fix command here] -n $NAMESPACE
\`\`\`

## Verification

\`\`\`bash
# Verify the fix worked
kubectl get pods -n $NAMESPACE
make room-escape-test ROOM=$ROOM_NAME
\`\`\`

## Learning Points

- [Key takeaway 1]
- [Key takeaway 2]
- [Key takeaway 3]

## Real-World Scenarios

This type of issue commonly occurs when:
- [Scenario 1]
- [Scenario 2]
SOLUTION_EOF

# =============================================================================
# Done!
# =============================================================================
echo -e "${GREEN}Room '$ROOM_NAME' created successfully!${NC}"
echo ""
echo "Created files:"
echo "  $ROOM_DIR/"
echo "    app.yaml          - Kubernetes manifest (edit to add your failure)"
echo "    tests.sh          - Validates broken state"
echo "    escape-tests.sh   - Validates fixed state"
echo "    OBJECTIVE.md      - Player instructions"
echo "    HINTS.md          - Progressive hints"
echo "    SOLUTION.md       - Full solution"
echo ""
echo -e "${YELLOW}Next steps:${NC}"
echo "  1. Edit app.yaml to create your failure scenario"
echo "  2. Update tests.sh to validate the broken state"
echo "  3. Update escape-tests.sh to validate the fixed state"
echo "  4. Fill in OBJECTIVE.md, HINTS.md, and SOLUTION.md"
echo "  5. Test with: make room-apply ROOM=$ROOM_NAME"
echo ""
