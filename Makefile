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

# Required files for a valid room (per RoomContract.md)
# Note: OBJECTIVE.md OR INCIDENT.md is also required (checked separately)
REQUIRED_FILES := app.yaml HINTS.md SOLUTION.md tests.sh

##@ General
.PHONY: help
help: ## Show all available commands
	@echo -e "$(CYAN)K8sEscapeRoom$(NC) - Debug Kubernetes failures to escape each room"
	@echo ""
	@echo "Usage: make [target] [ROOM=<room-name>]"
	@echo ""
	@echo -e "$(YELLOW)General:$(NC)"
	@echo -e "  $(GREEN)help$(NC)                       Show all available commands"
	@echo -e "  $(GREEN)tools-check$(NC)                Verify prerequisites are installed"
	@echo ""
	@echo -e "$(YELLOW)Cluster:$(NC)"
	@echo -e "  $(GREEN)cluster-up$(NC)                 Create the kind cluster"
	@echo -e "  $(GREEN)cluster-down$(NC)               Delete the kind cluster"
	@echo -e "  $(GREEN)cluster-status$(NC)             Show cluster status"
	@echo ""
	@echo -e "$(YELLOW)Rooms:$(NC)"
	@echo -e "  $(GREEN)room-list$(NC)                  List all available rooms"
	@echo -e "  $(GREEN)room-new ROOM=<name>$(NC)       Create a new room from template"
	@echo -e "  $(GREEN)room-apply ROOM=<name>$(NC)     Enter a room (apply broken state)"
	@echo -e "  $(GREEN)room-reset ROOM=<name>$(NC)     Reset a room (delete resources)"
	@echo -e "  $(GREEN)room-test ROOM=<name>$(NC)      Validate room is in broken state"
	@echo -e "  $(GREEN)room-verify ROOM=<name>$(NC)    Verify you escaped (fixed it)"
	@echo -e "  $(GREEN)room-objective ROOM=<name>$(NC) Show room objective"
	@echo -e "  $(GREEN)room-hint ROOM=<name>$(NC)      Show hints"
	@echo -e "  $(GREEN)room-solution ROOM=<name>$(NC)  Show solution"

##@ General
.PHONY: tools-check
tools-check: ## Verify prerequisites are installed
	@./scripts/tools-check.sh

##@ Cluster
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

##@ Rooms
.PHONY: room-new
room-new: ## Create a new room from template
ifndef ROOM
	@echo -e "$(RED)Error: ROOM is not set$(NC)"
	@echo ""
	@echo "Usage: make room-new ROOM=room-<name>"
	@echo ""
	@echo "Example:"
	@echo "  make room-new ROOM=room-oom-killed"
	@exit 1
endif
	@./scripts/room-new.sh $(ROOM)

.PHONY: room-list
room-list: ## List all available rooms
	@echo -e "$(CYAN)Available Escape Rooms:$(NC)"
	@echo ""
	@for room in rooms/room-*/ rooms/boss-*/; do \
		if [ -d "$$room" ]; then \
			room_name=$$(basename "$$room"); \
			if [ -f "$$room/OBJECTIVE.md" ]; then \
				objective=$$(head -n 3 "$$room/OBJECTIVE.md" | tail -n 1); \
				echo -e "  $(GREEN)$$room_name$(NC)"; \
				echo "    $$objective"; \
				echo ""; \
			elif [ -f "$$room/INCIDENT.md" ]; then \
				objective=$$(head -n 3 "$$room/INCIDENT.md" | tail -n 1); \
				echo -e "  $(GREEN)$$room_name$(NC) $(YELLOW)[BOSS]$(NC)"; \
				echo "    $$objective"; \
				echo ""; \
			fi; \
		fi; \
	done

.PHONY: room-apply
room-apply: _check-room _check-room-files ## Enter a room (apply broken state)
	@./scripts/room-apply.sh $(ROOM)

.PHONY: room-reset
room-reset: _check-room ## Reset a room (delete resources)
	@./scripts/room-reset.sh $(ROOM)

.PHONY: room-test
room-test: _check-room _check-room-files ## Validate room is in broken state
	@./scripts/room-test.sh $(ROOM)

.PHONY: room-escape-test
room-escape-test: _check-room ## Validate you escaped (fixed the room)
	@./scripts/room-escape-test.sh $(ROOM)

.PHONY: room-verify
room-verify: room-escape-test ## Alias for room-escape-test (verify you escaped)

.PHONY: room-objective
room-objective: _check-room ## Show room objective/incident
	@if [ -f "rooms/$(ROOM)/OBJECTIVE.md" ]; then \
		cat "rooms/$(ROOM)/OBJECTIVE.md"; \
	elif [ -f "rooms/$(ROOM)/INCIDENT.md" ]; then \
		cat "rooms/$(ROOM)/INCIDENT.md"; \
	else \
		echo -e "$(RED)Error: OBJECTIVE.md or INCIDENT.md not found for room '$(ROOM)'$(NC)"; \
		exit 1; \
	fi

.PHONY: room-hint
room-hint: _check-room ## Show hints
	@if [ -f "rooms/$(ROOM)/HINTS.md" ]; then \
		cat "rooms/$(ROOM)/HINTS.md"; \
	else \
		echo -e "$(RED)Error: HINTS.md not found for room '$(ROOM)'$(NC)"; \
		exit 1; \
	fi

.PHONY: room-solution
room-solution: _check-room ## Show solution
	@if [ -f "rooms/$(ROOM)/SOLUTION.md" ]; then \
		cat "rooms/$(ROOM)/SOLUTION.md"; \
	else \
		echo -e "$(RED)Error: SOLUTION.md not found for room '$(ROOM)'$(NC)"; \
		exit 1; \
	fi

##@ Internal
.PHONY: _check-room
_check-room:
ifndef ROOM
	@echo -e "$(RED)Error: ROOM is not set$(NC)"
	@echo ""
	@echo "Usage: make <target> ROOM=<room-name>"
	@echo ""
	@echo "Example:"
	@echo "  make room-apply ROOM=room-groundhog-deploy"
	@echo ""
	@echo "Run 'make room-list' to see available rooms."
	@exit 1
endif
	@if [ ! -d "rooms/$(ROOM)" ]; then \
		echo -e "$(RED)Error: Room '$(ROOM)' does not exist$(NC)"; \
		echo ""; \
		echo "Did you mean one of these?"; \
		for room in rooms/room-*/; do \
			echo "  $$(basename $$room)"; \
		done; \
		echo ""; \
		echo "Run 'make room-list' for details."; \
		exit 1; \
	fi

.PHONY: _check-room-files
_check-room-files:
	@missing=""; \
	for file in $(REQUIRED_FILES); do \
		if [ ! -f "rooms/$(ROOM)/$$file" ]; then \
			missing="$$missing $$file"; \
		fi; \
	done; \
	if [ ! -f "rooms/$(ROOM)/OBJECTIVE.md" ] && [ ! -f "rooms/$(ROOM)/INCIDENT.md" ]; then \
		missing="$$missing OBJECTIVE.md_or_INCIDENT.md"; \
	fi; \
	if [ -n "$$missing" ]; then \
		echo -e "$(RED)Error: Room '$(ROOM)' is incomplete$(NC)"; \
		echo ""; \
		echo "Missing required files:"; \
		for file in $$missing; do \
			if [ "$$file" = "OBJECTIVE.md_or_INCIDENT.md" ]; then \
				echo -e "  $(RED)✗$(NC) OBJECTIVE.md or INCIDENT.md"; \
			else \
				echo -e "  $(RED)✗$(NC) $$file"; \
			fi; \
		done; \
		echo ""; \
		echo "See docs/RoomContract.md for room requirements."; \
		exit 1; \
	fi; \
	if [ ! -x "rooms/$(ROOM)/tests.sh" ]; then \
		echo -e "$(RED)Error: tests.sh is not executable$(NC)"; \
		echo ""; \
		echo "Fix with: chmod +x rooms/$(ROOM)/tests.sh"; \
		exit 1; \
	fi

##@ CI (internal)
.PHONY: ci-test
ci-test: tools-check cluster-up
	@echo -e "$(CYAN)Running CI tests...$(NC)"
	@./scripts/room-apply.sh room-groundhog-deploy
	@./scripts/room-test.sh room-groundhog-deploy
	@echo -e "$(GREEN)CI tests passed!$(NC)"

.PHONY: ci-cleanup
ci-cleanup: cluster-down
	@echo -e "$(GREEN)CI cleanup complete$(NC)"
