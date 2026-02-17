#!/usr/bin/env bash
# room-reset.sh - Reset a room by deleting its namespace
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

ROOM_NAME="${1:-}"

RED='\033[0;31m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
NC='\033[0m'

if [ -z "$ROOM_NAME" ]; then
    echo -e "${RED}Error: Room name required${NC}"
    echo "Usage: $0 <room-name>"
    exit 1
fi

ROOM_DIR="${PROJECT_ROOT}/rooms/${ROOM_NAME}"

if [ ! -d "$ROOM_DIR" ]; then
    echo -e "${RED}Error: Room '${ROOM_NAME}' not found${NC}"
    exit 1
fi

NAMESPACE="escape-${ROOM_NAME}"

echo -e "${CYAN}Resetting room: ${ROOM_NAME}${NC}"

# Delete the namespace (which deletes all resources in it)
if kubectl get namespace "$NAMESPACE" &> /dev/null; then
    kubectl delete namespace "$NAMESPACE" --wait=false
    echo -e "${GREEN}Room '${ROOM_NAME}' has been reset.${NC}"
else
    echo -e "${GREEN}Room '${ROOM_NAME}' was not applied (nothing to reset).${NC}"
fi

# Run room-specific cleanup for cluster-scoped resources (if present)
if [ -x "$ROOM_DIR/reset-hook.sh" ]; then
    "$ROOM_DIR/reset-hook.sh"
fi

echo ""
echo "To re-enter the room:"
echo "  make room-apply ROOM=$ROOM_NAME"
