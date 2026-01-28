# K8sEscapeRoom Makefile
# Provides commands for cluster lifecycle and room management

SHELL := /bin/bash
.DEFAULT_GOAL := help

CLUSTER_NAME := k8s-escape-room
ROOM ?=

# Colors for output
CYAN := \033[0;36m
GREEN := \033[0;32m
YELLOW := \033[0;33m
RED := \033[0;31m
NC := \033[0m # No Color

.PHONY: help
help: ## Show this help message
	@echo -e "$(CYAN)K8sEscapeRoom$(NC) - Debug Kubernetes failures to escape each room"
	@echo ""
	@echo "Usage: make [target] [ROOM=<room-name>]"
	@echo ""
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | \
		awk 'BEGIN {FS = ":.*?## "}; {printf "  $(GREEN)%-20s$(NC) %s\n", $$1, $$2}'

.PHONY: tools-check
tools-check: ## Check that required tools are installed
	@./scripts/tools-check.sh

.PHONY: cluster-up
cluster-up: ## Create the kind cluster
	@./scripts/kind-create.sh $(CLUSTER_NAME)

.PHONY: cluster-down
cluster-down: ## Delete the kind cluster
	@./scripts/kind-delete.sh $(CLUSTER_NAME)

.PHONY: cluster-status
cluster-status: ## Show cluster status
	@if kind get clusters 2>/dev/null | grep -q "^$(CLUSTER_NAME)$$"; then \
		echo -e "$(GREEN)Cluster '$(CLUSTER_NAME)' is running$(NC)"; \
		kubectl cluster-info --context kind-$(CLUSTER_NAME) 2>/dev/null || true; \
	else \
		echo -e "$(YELLOW)Cluster '$(CLUSTER_NAME)' is not running$(NC)"; \
	fi

.PHONY: room-list
room-list: ## List all available rooms
	@echo -e "$(CYAN)Available Escape Rooms:$(NC)"
	@echo ""
	@for room in rooms/room-*/; do \
		room_name=$$(basename "$$room"); \
		if [ -f "$$room/OBJECTIVE.md" ]; then \
			objective=$$(head -n 3 "$$room/OBJECTIVE.md" | tail -n 1); \
			echo -e "  $(GREEN)$$room_name$(NC)"; \
			echo "    $$objective"; \
			echo ""; \
		fi \
	done

.PHONY: room-apply
room-apply: _check-room ## Apply a room's broken state (ROOM=<name>)
	@./scripts/room-apply.sh $(ROOM)

.PHONY: room-reset
room-reset: _check-room ## Reset a room (remove its resources) (ROOM=<name>)
	@./scripts/room-reset.sh $(ROOM)

.PHONY: room-test
room-test: _check-room ## Run tests for a room (ROOM=<name>)
	@./scripts/room-test.sh $(ROOM)

.PHONY: room-objective
room-objective: _check-room ## Show a room's objective (ROOM=<name>)
	@if [ -f "rooms/$(ROOM)/OBJECTIVE.md" ]; then \
		cat "rooms/$(ROOM)/OBJECTIVE.md"; \
	else \
		echo -e "$(RED)Error: OBJECTIVE.md not found for room '$(ROOM)'$(NC)"; \
		exit 1; \
	fi

.PHONY: room-hint
room-hint: _check-room ## Show hints for a room (ROOM=<name> LEVEL=1|2|3)
	@if [ -f "rooms/$(ROOM)/HINTS.md" ]; then \
		cat "rooms/$(ROOM)/HINTS.md"; \
	else \
		echo -e "$(RED)Error: HINTS.md not found for room '$(ROOM)'$(NC)"; \
		exit 1; \
	fi

.PHONY: room-solution
room-solution: _check-room ## Show solution for a room (ROOM=<name>)
	@if [ -f "rooms/$(ROOM)/SOLUTION.md" ]; then \
		cat "rooms/$(ROOM)/SOLUTION.md"; \
	else \
		echo -e "$(RED)Error: SOLUTION.md not found for room '$(ROOM)'$(NC)"; \
		exit 1; \
	fi

.PHONY: _check-room
_check-room:
ifndef ROOM
	$(error ROOM is not set. Usage: make <target> ROOM=<room-name>)
endif
	@if [ ! -d "rooms/$(ROOM)" ]; then \
		echo -e "$(RED)Error: Room '$(ROOM)' does not exist$(NC)"; \
		echo "Run 'make room-list' to see available rooms"; \
		exit 1; \
	fi

# CI targets
.PHONY: ci-test
ci-test: tools-check cluster-up ## Run CI tests (creates cluster, applies room, validates)
	@echo -e "$(CYAN)Running CI tests...$(NC)"
	@./scripts/room-apply.sh room-crashloop-env
	@sleep 10  # Allow time for pod to enter failure state
	@./scripts/room-test.sh room-crashloop-env
	@echo -e "$(GREEN)CI tests passed!$(NC)"

.PHONY: ci-cleanup
ci-cleanup: cluster-down ## Clean up CI resources
	@echo -e "$(GREEN)CI cleanup complete$(NC)"
