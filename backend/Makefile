# MongoCraft Backend Makefile

.PHONY: help install dev test lint format clean

help: ## Show this help message
	@echo "Available commands:"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-20s\033[0m %s\n", $$1, $$2}'

install: ## Install dependencies
	pip install -r requirements.txt

install-dev: ## Install development dependencies
	pip install -r requirements.txt
	pip install black isort flake8 mypy pytest pytest-asyncio

dev: ## Start development server
	uvicorn app.main:app --reload --host 0.0.0.0 --port 8000

dev-debug: ## Start development server with debug
	uvicorn app.main:app --reload --host 0.0.0.0 --port 8000 --log-level debug

test: ## Run tests
	pytest

test-verbose: ## Run tests with verbose output
	pytest -v

lint: ## Run linting
	flake8 app/
	mypy app/

format: ## Format code
	black app/
	isort app/

format-check: ## Check code formatting
	black --check app/
	isort --check-only app/

clean: ## Clean cache files
	find . -type d -name "__pycache__" -exec rm -rf {} +
	find . -type f -name "*.pyc" -delete
	find . -type d -name "*.egg-info" -exec rm -rf {} +

run-prod: ## Run in production mode
	uvicorn app.main:app --host 0.0.0.0 --port 8000