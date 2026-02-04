#!/usr/bin/env bash
# room-apply.sh - Apply a room's Kubernetes manifests
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

ROOM_NAME="${1:-}"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
CYAN='\033[0;36m'
NC='\033[0m'

# Required files per RoomContract.md
# Note: OBJECTIVE.md OR INCIDENT.md is required (boss rooms use INCIDENT.md)
REQUIRED_FILES=("app.yaml" "HINTS.md" "SOLUTION.md" "tests.sh")
OBJECTIVE_FILES=("OBJECTIVE.md" "INCIDENT.md")  # One of these is required

#######################################
# Print error and exit
#######################################
die() {
    echo -e "${RED}Error: $1${NC}" >&2
    exit 1
}

#######################################
# Validate room exists and has required files
#######################################
validate_room() {
    local room_dir="$1"
    local room_name="$2"

    # Check room directory exists
    if [ ! -d "$room_dir" ]; then
        echo -e "${RED}Error: Room '${room_name}' not found${NC}"
        echo ""
        echo "Available rooms:"
        for room in "$PROJECT_ROOT"/rooms/room-*/ "$PROJECT_ROOT"/rooms/boss-*/; do
            if [ -d "$room" ]; then
                echo "  $(basename "$room")"
            fi
        done
        echo ""
        echo "Run 'make room-list' for details."
        exit 1
    fi

    # Check required files exist
    local missing=()
    for file in "${REQUIRED_FILES[@]}"; do
        if [ ! -f "$room_dir/$file" ]; then
            missing+=("$file")
        fi
    done

    # Check for OBJECTIVE.md OR INCIDENT.md (one is required)
    local has_objective=false
    for file in "${OBJECTIVE_FILES[@]}"; do
        if [ -f "$room_dir/$file" ]; then
            has_objective=true
            break
        fi
    done
    if [ "$has_objective" = false ]; then
        missing+=("OBJECTIVE.md or INCIDENT.md")
    fi

    if [ ${#missing[@]} -gt 0 ]; then
        echo -e "${RED}Error: Room '${room_name}' is incomplete${NC}"
        echo ""
        echo "Missing required files:"
        for file in "${missing[@]}"; do
            echo -e "  ${RED}✗${NC} $file"
        done
        echo ""
        echo "Present files:"
        for file in "${REQUIRED_FILES[@]}"; do
            if [ -f "$room_dir/$file" ]; then
                echo -e "  ${GREEN}✓${NC} $file"
            fi
        done
        for file in "${OBJECTIVE_FILES[@]}"; do
            if [ -f "$room_dir/$file" ]; then
                echo -e "  ${GREEN}✓${NC} $file"
            fi
        done
        echo ""
        echo "See docs/RoomContract.md for room requirements."
        exit 1
    fi

    # Check tests.sh is executable
    if [ ! -x "$room_dir/tests.sh" ]; then
        echo -e "${RED}Error: tests.sh is not executable${NC}"
        echo ""
        echo "Fix with:"
        echo "  chmod +x $room_dir/tests.sh"
        exit 1
    fi

    # Check at least one YAML manifest exists
    local yaml_count
    yaml_count=$(find "$room_dir" -maxdepth 1 -name "*.yaml" -type f | wc -l)
    if [ "$yaml_count" -eq 0 ]; then
        die "No YAML manifests found in room '${room_name}'"
    fi
}

#######################################
# Main
#######################################

if [ -z "$ROOM_NAME" ]; then
    echo -e "${RED}Error: Room name required${NC}"
    echo ""
    echo "Usage: $0 <room-name>"
    echo ""
    echo "Example:"
    echo "  $0 room-crashloop-env"
    exit 1
fi

ROOM_DIR="${PROJECT_ROOT}/rooms/${ROOM_NAME}"

# Validate room before proceeding
validate_room "$ROOM_DIR" "$ROOM_NAME"

echo -e "${CYAN}Entering escape room: ${ROOM_NAME}${NC}"
echo ""

# Create namespace for the room
NAMESPACE="escape-${ROOM_NAME}"
echo -n "Creating namespace ${NAMESPACE}... "
if kubectl create namespace "$NAMESPACE" --dry-run=client -o yaml 2>/dev/null | kubectl apply -f - >/dev/null 2>&1; then
    echo -e "${GREEN}done${NC}"
else
    echo -e "${YELLOW}already exists${NC}"
fi

# Apply all YAML files in the room directory
echo ""
echo "Applying manifests:"
for manifest in "$ROOM_DIR"/*.yaml; do
    if [ -f "$manifest" ]; then
        echo -n "  $(basename "$manifest")... "
        if kubectl apply -f "$manifest" -n "$NAMESPACE" >/dev/null 2>&1; then
            echo -e "${GREEN}applied${NC}"
        else
            echo -e "${RED}failed${NC}"
            kubectl apply -f "$manifest" -n "$NAMESPACE"  # Re-run to show error
            exit 1
        fi
    fi
done

echo ""
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}Room '${ROOM_NAME}' is now active.${NC}"
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo -e "${CYAN}You are now trapped! Debug the cluster to escape.${NC}"
echo ""
echo "Start investigating:"
echo -e "  ${GREEN}kubectl get pods -n $NAMESPACE${NC}"
echo -e "  ${GREEN}kubectl describe pod escape-app -n $NAMESPACE${NC}"
echo -e "  ${GREEN}kubectl logs escape-app -n $NAMESPACE${NC}"
echo ""
echo "When you're stuck:"
echo -e "  ${YELLOW}make room-objective ROOM=$ROOM_NAME${NC}  # What you need to achieve"
echo -e "  ${YELLOW}make room-hint ROOM=$ROOM_NAME${NC}       # Get hints"
echo -e "  ${YELLOW}make room-solution ROOM=$ROOM_NAME${NC}   # See the solution"
echo ""
echo "To exit and reset:"
echo -e "  ${YELLOW}make room-reset ROOM=$ROOM_NAME${NC}"
