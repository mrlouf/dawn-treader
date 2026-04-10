.PHONY: build up down logs clean help

help: ## Show this help message
	@echo 'Usage: make [target]'
	@echo ''
	@echo 'Available targets:'
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "  %-15s %s\n", $$1, $$2}' $(MAKEFILE_LIST)

build: ## Build all Docker images
	docker compose build

up: ## Start all services
	docker compose up -d
	@echo ""
	@echo "✅ All services started!"
	@echo "🌐 Access the application at http://localhost"
	@echo ""

down: ## Stop all services
	docker compose down

logs: ## Show logs from all services
	docker compose logs -f

logs-backend: ## Show backend logs
	docker compose logs -f backend

logs-frontend: ## Show frontend logs
	docker compose logs -f frontend

logs-nginx: ## Show nginx logs
	docker compose logs -f nginx

clean: ## Stop services and remove volumes
	docker compose down -v
	docker system prune -f

rebuild: down build up ## Rebuild and restart all services

status: ## Show status of all services
	docker compose ps
