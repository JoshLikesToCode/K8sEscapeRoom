#!/usr/bin/env bash
# room-test.sh - Run tests for a room to validate its failure state
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
TEST_FILE="${ROOM_DIR}/tests.sh"

if [ ! -d "$ROOM_DIR" ]; then
    echo -e "${RED}Error: Room '${ROOM_NAME}' not found${NC}"
    exit 1
fi

if [ ! -f "$TEST_FILE" ]; then
    echo -e "${RED}Error: No tests.sh found for room '${ROOM_NAME}'${NC}"
    exit 1
fi

echo -e "${CYAN}Running tests for room: ${ROOM_NAME}${NC}"
echo ""

# Export the namespace for the test script
export NAMESPACE="escape-${ROOM_NAME}"

# Run the room's test script
bash "$TEST_FILE"

TEST_EXIT_CODE=$?

echo ""
if [ $TEST_EXIT_CODE -eq 0 ]; then
    echo -e "${GREEN}All tests passed for room '${ROOM_NAME}'${NC}"
else
    echo -e "${RED}Tests failed for room '${ROOM_NAME}'${NC}"
    exit $TEST_EXIT_CODE
fi
