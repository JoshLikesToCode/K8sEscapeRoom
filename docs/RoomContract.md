# Room Contract

This document defines the contract that every K8sEscapeRoom room must follow.

## Directory Structure

Every room must be located in `rooms/room-<name>/` and contain these files:

```
rooms/room-<name>/
├── app.yaml            # Kubernetes manifest(s) with intentional bug
├── OBJECTIVE.md        # What the user must achieve to escape
├── HINTS.md            # Progressive hints (Level 1-4)
├── SOLUTION.md         # Complete diagnosis and fix
├── tests.sh            # Script to validate the broken state
└── escape-tests.sh     # Script to validate the fixed state (optional)
```

## Scaffolding a New Room

Use the room generator to create all required files:

```bash
make room-new ROOM=room-my-scenario
```

This creates the directory structure with templates that you customize.

## Naming Conventions

### Room Names
- Format: `room-<descriptive-name>`
- Use lowercase with hyphens
- Examples: `room-crashloop-env`, `room-imagepullbackoff`, `room-pending-resources`

### Namespaces
- Format: `escape-<room-name>`
- Each room runs in its own namespace
- Example: Room `room-crashloop-env` → Namespace `escape-room-crashloop-env`

### Resource Names
- Primary pod/deployment: `escape-app`
- Supporting resources: `escape-<purpose>` (e.g., `escape-db`, `escape-config`)

## Required Labels

All Kubernetes resources must include these labels:

```yaml
metadata:
  labels:
    # Kubernetes recommended labels
    app.kubernetes.io/name: escape-app
    app.kubernetes.io/part-of: K8sEscapeRoom
    app.kubernetes.io/component: challenge

    # K8sEscapeRoom labels
    k8sescaperoom.dev/room: room-<name>
    k8sescaperoom.dev/difficulty: beginner|intermediate|advanced
    k8sescaperoom.dev/failure-mode: <expected-status>
```

### Label Definitions

| Label | Required | Description |
|-------|----------|-------------|
| `app.kubernetes.io/name` | Yes | Resource name (usually `escape-app`) |
| `app.kubernetes.io/part-of` | Yes | Always `K8sEscapeRoom` |
| `app.kubernetes.io/component` | Yes | Always `challenge` |
| `k8sescaperoom.dev/room` | Yes | Full room name |
| `k8sescaperoom.dev/difficulty` | Yes | `beginner`, `intermediate`, or `advanced` |
| `k8sescaperoom.dev/failure-mode` | Yes | Expected pod status (e.g., `CrashLoopBackOff`) |

## Optional Annotations

```yaml
metadata:
  annotations:
    k8sescaperoom.dev/description: "Brief description of the failure"
```

## File Requirements

### app.yaml

- Must contain valid Kubernetes manifests
- Must have an intentional bug that causes a specific failure mode
- Must include all required labels and annotations
- Should include comments explaining the intentional bug (for maintainers)

```yaml
# Room: <Title>
# <Brief description of what's broken>
apiVersion: v1
kind: Pod
metadata:
  name: escape-app
  labels:
    app.kubernetes.io/name: escape-app
    app.kubernetes.io/part-of: K8sEscapeRoom
    # ... rest of required labels
```

### OBJECTIVE.md

Must include:
1. Title with room name
2. Brief problem description
3. Clear success criteria
4. Getting started commands
5. Namespace information

Template:
```markdown
# Escape Room: <Title>

<One-line problem description>

## Your Mission

1. <Step 1>
2. <Step 2>
3. <Step 3>

## Success Criteria

- <Measurable criterion 1>
- <Measurable criterion 2>

## Getting Started

\`\`\`bash
kubectl get pods -n <namespace>
\`\`\`

## Namespace

All resources are in the `<namespace>` namespace.
```

### HINTS.md

Must include 4 progressive hint levels:
- **Level 1**: Where to look (which commands to run)
- **Level 2**: What to look for (what the error indicates)
- **Level 3**: The problem (specific issue identified)
- **Level 4**: How to fix (approach without full solution)

Template:
```markdown
# Hints: <Title>

---

## Hint Level 1: Where to Look
<General guidance on investigation approach>

---

## Hint Level 2: What to Look For
<More specific guidance on interpreting output>

---

## Hint Level 3: The Problem
<Identifies the specific issue>

---

## Hint Level 4: How to Fix
<Approach to fixing without exact commands>
```

### SOLUTION.md

Must include:
1. Root cause explanation
2. Diagnosis steps with commands
3. The fix (at least one method, preferably two)
4. Verification steps
5. Lessons learned
6. Real-world considerations

### tests.sh

Must:
- Be executable (`chmod +x`)
- Use `set -euo pipefail`
- Accept `NAMESPACE` environment variable
- Output clear PASS/FAIL for each test
- Return exit code 0 only if all tests pass
- Validate the room is in the expected **broken** state

Template:
```bash
#!/usr/bin/env bash
set -euo pipefail

NAMESPACE="${NAMESPACE:-escape-room-<name>}"
POD_NAME="escape-app"

# Test 1: Pod exists
echo -n "Test 1: Pod exists... "
# ... validation logic

# Test 2: Pod is in expected failure state
echo -n "Test 2: Pod is in failure state... "
# ... validation logic

echo "All tests passed!"
```

### escape-tests.sh (Optional)

Validates that the room has been **fixed** (escaped). This runs after the user attempts to fix the issue.

Must:
- Be executable (`chmod +x`)
- Use `set -euo pipefail`
- Source `test-helpers.sh` for shared utilities
- Validate the pod is Running and Ready
- Check room-specific success criteria (e.g., logs show success message)
- Print congratulations message on success

Template:
```bash
#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../../scripts/test-helpers.sh"

NAMESPACE="escape-room-<name>"
POD_LABEL="app=escape-app"

echo "=== Testing room-<name> (escaped/fixed state) ==="

# Check pod is running
test_start "Pod is Running"
if wait_for_condition "$NAMESPACE" "$POD_LABEL" "Ready" "True" 30; then
    test_pass "Pod is Running and Ready"
else
    test_fail "Pod is not in Running/Ready state"
fi

# Room-specific checks...

echo ""
echo "CONGRATULATIONS! You escaped the room!"
```

## Validation

Before submitting a new room, verify:

```bash
# 1. All required files exist
ls rooms/room-<name>/{app.yaml,OBJECTIVE.md,HINTS.md,SOLUTION.md,tests.sh}

# 2. Test scripts are executable
test -x rooms/room-<name>/tests.sh
test -x rooms/room-<name>/escape-tests.sh  # If present

# 3. Manifests have required labels
grep -q "app.kubernetes.io/part-of" rooms/room-<name>/app.yaml
grep -q "k8sescaperoom.dev/room:" rooms/room-<name>/app.yaml

# 4. Room applies and enters expected broken state
make room-apply ROOM=room-<name>
make room-test ROOM=room-<name>

# 5. Fix the room and verify escape validation works
# (manually fix the issue, then run:)
make room-escape-test ROOM=room-<name>

# 6. Room can be reset
make room-reset ROOM=room-<name>
```

## CI Enforcement

The CI pipeline validates every room by:
1. Applying the room
2. Waiting for the failure state
3. Running `tests.sh` to verify the broken state
4. Resetting the room

All rooms must pass CI before merging.
