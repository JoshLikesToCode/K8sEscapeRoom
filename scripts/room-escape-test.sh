#!/usr/bin/env bash
# room-escape-test.sh - Verify that a room has been escaped (fixed)
#
# This script runs the escape-tests.sh for a room to validate that
# the user has successfully fixed all the issues.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

ROOM_NAME="${1:-}"

# Colors
RED='\033[0;31m'
YELLOW='\033[0;33m'
CYAN='\033[0;36m'
NC='\033[0m'

#######################################
# Print error and exit
#######################################
die() {
    echo -e "${RED}Error: $1${NC}" >&2
    exit 1
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

# Check room exists
if [ ! -d "$ROOM_DIR" ]; then
    echo -e "${RED}Error: Room '${ROOM_NAME}' not found${NC}"
    echo ""
    echo "Available rooms:"
    for room in "$PROJECT_ROOT"/rooms/room-*/ "$PROJECT_ROOT"/rooms/boss-*/; do
        if [ -d "$room" ]; then
            echo "  $(basename "$room")"
        fi
    done
    exit 1
fi

# Check escape-tests.sh exists
ESCAPE_TEST="${ROOM_DIR}/escape-tests.sh"
if [ ! -f "$ESCAPE_TEST" ]; then
    echo -e "${YELLOW}Warning: escape-tests.sh not found for room '${ROOM_NAME}'${NC}"
    echo ""
    echo "This room doesn't have escape validation tests yet."
    echo "You can manually verify by checking:"
    echo "  - Pods are Running and Ready"
    echo "  - Service endpoints exist (if applicable)"
    echo "  - Application is accessible"
    exit 0
fi

# Check it's executable
if [ ! -x "$ESCAPE_TEST" ]; then
    echo -e "${RED}Error: escape-tests.sh is not executable${NC}"
    echo ""
    echo "Fix with:"
    echo "  chmod +x $ESCAPE_TEST"
    exit 1
fi

echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${CYAN}Verifying escape: ${ROOM_NAME}${NC}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

# Run the escape tests
exec "$ESCAPE_TEST"
