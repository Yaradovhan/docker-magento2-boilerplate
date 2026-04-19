SHELL := /bin/bash

# -----------------------------
# Environment
# -----------------------------
-include .env

DOMAIN ?= myproject.m2.loc
COMPOSE_PROJECT_NAME ?= m2
APP_PATH ?= application
COMPOSE ?= docker compose
APP_SERVICE ?= app
NGINX_SSL_PORT ?= 443

BASE_URL ?= http://$(DOMAIN)/
SECURE_BASE_URL ?= https://$(DOMAIN)$(if $(filter-out 443,$(NGINX_SSL_PORT)),:$(NGINX_SSL_PORT),)/

MAGENTO_INSTALL_FLAGS ?= --base-url=$(BASE_URL) \
	--backend-frontname=admin \
	--db-host=mariadb \
	--db-name=$(MARIADB_DATABASE) \
	--db-user=$(MARIADB_USER) \
	--db-password=$(MARIADB_PASSWORD) \
	--admin-firstname=Admin \
	--admin-lastname=Admin \
	--admin-email=$(ADMIN_EMAIL) \
	--admin-user=$(ADMIN_USER) \
	--admin-password=$(ADMIN_PASSWORD) \
	--language=en_US \
	--currency=USD \
	--timezone=$(APP_TIMEZONE) \
	--use-rewrites=1

GITHUB_REPO ?=

.DEFAULT_GOAL := help

.PHONY: help setup full-setup init hosts ssl ssl-config build up start stop restart down clean reset pull ps status logs logs-app logs-nginx logs-db shell root-shell composer composer-i npm node m2 create-project install post-install reinstall compile static cache upgrade reindex deploy-mode-dev permissions clear-static rebuild validate config sample-data bash db-import

# -----------------------------
# Help
# -----------------------------
help:
	@echo "Magento 2 Docker Environment"
	@echo "Main Commands:"
	@echo "  make setup          - Full setup including clone and install"
	@echo "  make full-setup     - Setup + hosts hint + Magento install + post-install"
	@echo "  make reset          - Full Docker/project reset"
	@echo ""
	@echo "Docker Commands:"
	@echo "  make build          - Build Docker images"
	@echo "  make up             - Start Docker containers"
	@echo "  make down           - Stop Docker containers"
	@echo "  make logs           - View all service logs"
	@echo "  make db-import      - Run database import"
	@echo ""
	@echo "Magento Commands:"
	@echo "  make upgrade        - Run setup:upgrade"
	@echo "  make compile        - Setup:di:compile"
	@echo "  make static         - Deploy static content"
	@echo "  make cache          - Flush cache"
	@echo "  make reindex        - Reindex"
	@echo ""
	@echo "Detected OS: $(OS)"
	@echo "Compose project: $(COMPOSE_PROJECT_NAME)"
	@echo "HTTP URL: $(BASE_URL)"
	@echo "HTTPS URL: $(SECURE_BASE_URL)"

# -----------------------------
# Bootstrap
# -----------------------------
init:
	@if [ ! -f .env ] && [ -f .env.example ]; then \
		cp .env.example .env; \
		echo "Created .env from .env.example"; \
	elif [ -f .env ]; then \
		echo ".env already exists"; \
	else \
		echo "No .env.example found, skipping"; \
	fi

setup: init clone-repo ssl up composer-install
	@echo "Next steps:"
	@echo "  make hosts"

full-setup: setup
	$(MAKE) hosts
	$(MAKE) install
	$(MAKE) post-install

hosts:
	@echo "Run this command to add the domain to /etc/hosts:"
	@echo "  echo '127.0.0.1 $(DOMAIN)' | sudo tee -a /etc/hosts"

ssl:
	@mkdir -p images/application/nginx/certs
	@if ! command -v mkcert >/dev/null 2>&1; then \
		echo "mkcert is not installed."; \
		exit 1; \
	fi
	mkcert -install
	mkcert -cert-file images/application/nginx/certs/$(DOMAIN).pem -key-file images/application/nginx/certs/$(DOMAIN)-key.pem $(DOMAIN) localhost 127.0.0.1 ::1

ssl-config:
	$(MAKE) m2 ARGS='config:set web/secure/base_url $(SECURE_BASE_URL)'
	$(MAKE) m2 ARGS='config:set web/unsecure/base_url $(BASE_URL)'
	$(MAKE) cache

# -----------------------------
# Docker lifecycle
# -----------------------------
build:
	$(COMPOSE) build

up:
	$(COMPOSE) up -d --build

down:
	$(COMPOSE) down

logs:
	$(COMPOSE) logs -f --tail=150

# -----------------------------
# Magento setup
# -----------------------------
clone-repo:
	@if [ -z "$(GITHUB_REPO)" ]; then \
		echo "GITHUB_REPO is not set, skipping clone."; \
		mkdir -p "$(APP_PATH)"; \
	elif [ -d "$(APP_PATH)/.git" ]; then \
		echo "Repository already cloned in $(APP_PATH)."; \
	elif [ -d "$(APP_PATH)" ] && [ -z "$$(find "$(APP_PATH)" -mindepth 1 ! -name '.DS_Store' -print -quit)" ]; then \
		echo "Directory $(APP_PATH) exists but is empty. Cloning into it..."; \
		rm -f "$(APP_PATH)/.DS_Store"; \
		tmp_dir="$$(mktemp -d)"; \
		git clone $(GITHUB_REPO) "$$tmp_dir/repo" && \
		cp -R "$$tmp_dir/repo/." "$(APP_PATH)/" && \
		rm -rf "$$tmp_dir"; \
	elif [ ! -d "$(APP_PATH)" ]; then \
		git clone $(GITHUB_REPO) $(APP_PATH); \
	else \
		echo "Directory $(APP_PATH) already exists and is not empty, but it is not a git repository."; \
		echo "Please clean $(APP_PATH) or point APP_PATH to another directory."; \
		exit 1; \
	fi

composer-install:
	$(COMPOSE) exec -w / $(APP_SERVICE) sh -c 'cd /var/www/html && if [ -f "composer.json" ]; then composer install; else echo "composer.json not found in /var/www/html"; exit 1; fi'

create-project:
	@if [ -f "$(APP_PATH)/composer.json" ]; then \
		echo "composer.json already exists in $(APP_PATH), skipping create-project."; \
	else \
		$(COMPOSE) exec -w / $(APP_SERVICE) composer create-project --repository-url=https://repo.magento.com/ magento/project-community-edition /var/www/html; \
	fi

install:
	$(MAKE) m2 ARGS='setup:install $(MAGENTO_INSTALL_FLAGS)'

post-install:
	$(MAKE) m2 ARGS='module:disable Magento_TwoFactorAuth'
	$(MAKE) deploy-mode-dev
	$(MAKE) ssl-config
	$(MAKE) permissions

reinstall:
	$(MAKE) m2 ARGS='setup:uninstall --no-interaction'
	$(MAKE) install
	$(MAKE) post-install

# -----------------------------
# Magento commands
# -----------------------------
upgrade:
	$(MAKE) m2 ARGS='setup:upgrade'

compile:
	$(MAKE) m2 ARGS='setup:di:compile'

static:
	$(MAKE) m2 ARGS='setup:static-content:deploy -f'

cache:
	$(MAKE) m2 ARGS='cache:flush'

reindex:
	$(MAKE) m2 ARGS='indexer:reindex'

deploy-mode-dev:
	$(MAKE) m2 ARGS='deploy:mode:set developer'

# -----------------------------
# Dev helpers
# -----------------------------
permissions:
	$(COMPOSE) exec -u root $(APP_SERVICE) chown -R www-data:www-data /var/www/html/var /var/www/html/generated /var/www/html/pub/static
	$(COMPOSE) exec -u root $(APP_SERVICE) find /var/www/html/var /var/www/html/generated /var/www/html/pub/static -type d -exec chmod 775 {} \;
	$(COMPOSE) exec -u root $(APP_SERVICE) find /var/www/html/var /var/www/html/generated /var/www/html/pub/static -type f -exec chmod 664 {} \;

clear-static:
	$(COMPOSE) exec $(APP_SERVICE) rm -rf pub/static/frontend/* var/view_preprocessed/* pub/static/_cache/*

rebuild:
	$(MAKE) clear-static
	$(MAKE) compile
	$(MAKE) static
	$(MAKE) cache
	$(MAKE) permissions

db-import:
	@read -p "Database name: " db; \
	read -p "Path to .sql.gz file: " file; \
	if [ ! -f "$$file" ]; then \
		echo "File not found: $$file"; \
		exit 1; \
	fi; \
	echo "Importing $$file into $$db..."; \
	gunzip -c "$$file" | $(COMPOSE) exec -T mariadb mysql -u$(MARIADB_USER) -p$(MARIADB_PASSWORD) "$$db"; \
	echo "Done."

validate:
	$(COMPOSE) config --quiet

config:
	$(COMPOSE) config

reset:
	@echo "Full Docker/project reset..."
	$(COMPOSE) down -v --remove-orphans --rmi local
	docker container prune -f --filter "label=com.docker.compose.project=$(COMPOSE_PROJECT_NAME)"
	docker volume prune -f --filter "label=com.docker.compose.project=$(COMPOSE_PROJECT_NAME)"
	rm -rf data/db/data data/logs data/opensearch data/redis data/rabbitmq
	rm -rf $(APP_PATH)/var/cache $(APP_PATH)/var/page_cache $(APP_PATH)/var/di $(APP_PATH)/var/view_preprocessed $(APP_PATH)/generated $(APP_PATH)/pub/static/*
	rm -f $(APP_PATH)/app/etc/env.php $(APP_PATH)/app/etc/config.php
	@echo "Project reset completed"

# -----------------------------
# Command wrappers
# -----------------------------
m2:
	$(COMPOSE) exec $(APP_SERVICE) php bin/magento $(ARGS)
