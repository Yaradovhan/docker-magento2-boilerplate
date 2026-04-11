SHELL := /bin/bash

# -----------------------------
# Environment
# -----------------------------
-include .env

# Detect OS
OS := $(shell uname)
LINUX_DISTRO := $(shell if [ "$(OS)" = "Linux" ] && command -v grep >/dev/null 2>&1 && [ -f /etc/os-release ]; then grep '^ID=' /etc/os-release | cut -d= -f2 | tr -d '"'; fi)

# -----------------------------
# Base config
# -----------------------------
COMPOSE ?= docker compose
APP_SERVICE ?= app
DOMAIN ?= docker.m2.loc
APP_PATH ?= application
NGINX_SSL_PORT ?= 443
BASE_URL ?= http://$(DOMAIN)/
SECURE_BASE_URL ?= https://$(DOMAIN)$(if $(filter-out 443,$(NGINX_SSL_PORT)),:$(NGINX_SSL_PORT),)/

MAGENTO_INSTALL_FLAGS ?= --base-url=$(BASE_URL) \
	--backend-frontname=admin \
	--db-host=mariadb \
	--db-name=magento \
	--db-user=magento \
	--db-password=magento \
	--admin-firstname=Admin \
	--admin-lastname=Admin \
	--admin-email=admin@example.com \
	--admin-user=admin \
	--admin-password=admin123 \
	--language=en_US \
	--currency=USD \
	--timezone=Europe/Kyiv \
	--use-rewrites=1 \
	--search-engine=opensearch \
	--opensearch-host=opensearch \
	--opensearch-port=9200 \
	--session-save=redis \
	--session-save-redis-host=redis \
	--session-save-redis-port=6379 \
	--session-save-redis-db=2 \
	--cache-backend=redis \
	--cache-backend-redis-server=redis \
	--cache-backend-redis-port=6379 \
	--cache-backend-redis-db=0 \
	--page-cache=redis \
	--page-cache-redis-server=redis \
	--page-cache-redis-port=6379 \
	--page-cache-redis-db=1 \
	--amqp-host=rabbitmq \
	--amqp-port=5672 \
	--amqp-user=magento \
	--amqp-password=magento

.DEFAULT_GOAL := help

.PHONY: help setup init hosts ssl ssl-config smtp-config build up start stop restart down clean reset pull \
	ps status logs logs-app logs-nginx logs-db shell root-shell composer composer-i npm node m2 \
	create-project install post-install reinstall compile static cache upgrade reindex \
	deploy-mode-dev permissions clear-static rebuild validate config sample-data bash

# -----------------------------
# Help
# -----------------------------
help:
	@echo "Magento 2 Docker Environment"
	@echo ""
	@echo "Main:"
	@echo "  make setup           - bootstrap project after clone"
	@echo "  make create-project  - create Magento project in application/"
	@echo "  make install         - run Magento setup:install"
	@echo "  make post-install    - disable 2FA + developer mode + HTTPS config + cache flush"
	@echo "  make reinstall       - reinstall Magento from scratch"
	@echo "  make reset           - full Docker/project reset with project image cleanup"
	@echo ""
	@echo "SSL:"
	@echo "  make ssl             - generate local mkcert certificates"
	@echo "  make ssl-config      - configure Magento secure URLs"
	@echo "  make smtp-config     - configure Mageplaza SMTP for local Mailpit"
	@echo ""
	@echo "Containers:"
	@echo "  make build           - build images"
	@echo "  make up              - start containers"
	@echo "  make stop            - stop containers"
	@echo "  make restart         - restart containers"
	@echo "  make down            - stop and remove containers"
	@echo "  make clean           - down with orphan cleanup"
	@echo "  make pull            - pull service images"
	@echo "  make ps              - show container status"
	@echo "  make status          - show compose status and project URLs"
	@echo "  make logs            - all service logs"
	@echo "  make logs-app        - app logs"
	@echo "  make logs-nginx      - nginx logs"
	@echo "  make logs-db         - mariadb logs"
	@echo "  make shell           - open shell in app container"
	@echo "  make root-shell      - open root shell in app container"
	@echo ""
	@echo "Magento:"
	@echo "  make compile         - setup:di:compile"
	@echo "  make static          - static content deploy"
	@echo "  make cache           - cache flush"
	@echo "  make upgrade         - setup:upgrade"
	@echo "  make reindex         - indexer:reindex"
	@echo "  make deploy-mode-dev - developer mode"
	@echo "  make composer ARGS='install'    - run composer"
	@echo "  make composer-i      - run composer install"
	@echo "  make m2 ARGS='cache:flush'      - run bin/magento"
	@echo ""
	@echo "Other:"
	@echo "  make hosts           - print hosts entry"
	@echo "  make permissions     - fix Magento writable permissions"
	@echo "  make clear-static    - remove generated static frontend assets"
	@echo "  make rebuild         - clear static + compile + deploy + cache"
	@echo "  make validate        - validate docker compose config"
	@echo "  make config          - show rendered docker compose config"
	@echo ""
	@echo "Detected OS: $(OS) $(LINUX_DISTRO)"
	@echo "HTTP URL:    $(BASE_URL)"
	@echo "HTTPS URL:   $(SECURE_BASE_URL)"

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

setup: init ssl up
	@echo ""
	@echo "Next steps:"
	@echo "  1. make hosts"
	@echo "  2. make create-project"
	@echo "  3. make install"
	@echo "  4. make post-install"

hosts:
	@echo "Add this line to /etc/hosts:"
	@echo "127.0.0.1 $(DOMAIN)"

ssl:
	@mkdir -p images/application/nginx/certs
	@if ! command -v mkcert >/dev/null 2>&1; then \
		echo "mkcert is not installed."; \
		echo "Install it first: brew install mkcert"; \
		exit 1; \
	fi
	mkcert -install
	mkcert \
		-cert-file images/application/nginx/certs/$(DOMAIN).pem \
		-key-file images/application/nginx/certs/$(DOMAIN)-key.pem \
		$(DOMAIN) localhost 127.0.0.1 ::1

ssl-config:
	$(MAKE) m2 ARGS='config:set web/unsecure/base_url $(BASE_URL)'
	$(MAKE) m2 ARGS='config:set web/secure/base_url $(SECURE_BASE_URL)'
	$(MAKE) m2 ARGS='config:set web/secure/use_in_frontend 1'
	$(MAKE) m2 ARGS='config:set web/secure/use_in_adminhtml 1'
	$(MAKE) cache

smtp-config:
	$(MAKE) m2 ARGS='config:set smtp/general/enabled 1'
	$(MAKE) m2 ARGS='config:set smtp/configuration_option/host mail'
	$(MAKE) m2 ARGS='config:set smtp/configuration_option/port 1025'
	$(MAKE) m2 ARGS='config:set smtp/configuration_option/protocol ""'
	$(MAKE) m2 ARGS='config:set smtp/configuration_option/authentication smtp'
	$(MAKE) m2 ARGS='config:set smtp/configuration_option/username ""'
	$(MAKE) m2 ARGS='config:set smtp/configuration_option/password ""'
	$(MAKE) m2 ARGS='config:set smtp/configuration_option/return_path_email ""'
	$(MAKE) cache

# -----------------------------
# Docker lifecycle
# -----------------------------
build:
	$(COMPOSE) build

up:
	$(COMPOSE) up -d --build

start:
	$(COMPOSE) start

stop:
	$(COMPOSE) stop

restart:
	$(COMPOSE) restart

down:
	$(COMPOSE) down

clean:
	$(COMPOSE) down --remove-orphans

pull:
	$(COMPOSE) pull

ps:
	$(COMPOSE) ps

status:
	@$(COMPOSE) ps
	@echo ""
	@echo "Storefront HTTP:  $(BASE_URL)"
	@echo "Storefront HTTPS: $(SECURE_BASE_URL)"
	@echo "Admin HTTPS:      $(SECURE_BASE_URL)admin"

logs:
	$(COMPOSE) logs -f --tail=150

logs-app:
	$(COMPOSE) logs -f --tail=150 $(APP_SERVICE)

logs-nginx:
	$(COMPOSE) logs -f --tail=150 nginx

logs-db:
	$(COMPOSE) logs -f --tail=150 mariadb

# -----------------------------
# Container helpers
# -----------------------------
shell:
	$(COMPOSE) exec $(APP_SERVICE) sh -lc "bash || sh"

bash: shell

root-shell:
	$(COMPOSE) exec -u root $(APP_SERVICE) sh -lc "bash || sh"

composer:
	$(COMPOSE) exec $(APP_SERVICE) composer $(ARGS)

composer-i:
	$(COMPOSE) exec $(APP_SERVICE) composer install

npm:
	$(COMPOSE) exec $(APP_SERVICE) npm $(ARGS)

node:
	$(COMPOSE) exec $(APP_SERVICE) node $(ARGS)

m2:
	$(COMPOSE) exec $(APP_SERVICE) php bin/magento $(ARGS)

# -----------------------------
# Magento setup
# -----------------------------
create-project:
	$(COMPOSE) exec $(APP_SERVICE) composer create-project --repository-url=https://repo.magento.com/ magento/project-community-edition $(if $(ARGS),$(ARGS),.) .

install:
	$(MAKE) m2 ARGS='setup:install $(MAGENTO_INSTALL_FLAGS)'

post-install:
	$(MAKE) m2 ARGS='module:disable Magento_AdminAdobeImsTwoFactorAuth Magento_TwoFactorAuth'
	$(MAKE) upgrade
	$(MAKE) deploy-mode-dev
	$(MAKE) ssl-config
	$(MAKE) smtp-config
	$(MAKE) permissions

reinstall:
	$(MAKE) m2 ARGS='setup:uninstall --no-interaction'
	$(MAKE) install
	$(MAKE) post-install

sample-data:
	$(MAKE) m2 ARGS='sampledata:deploy'
	$(MAKE) composer ARGS='update'

# -----------------------------
# Magento commands
# -----------------------------
compile:
	$(MAKE) m2 ARGS='setup:di:compile'

static:
	$(MAKE) m2 ARGS='setup:static-content:deploy -f'

cache:
	$(MAKE) m2 ARGS='cache:flush'

upgrade:
	$(MAKE) m2 ARGS='setup:upgrade'

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
	$(COMPOSE) exec $(APP_SERVICE) sh -lc "rm -rf pub/static/frontend/* var/view_preprocessed/* pub/static/_cache/*"

rebuild:
	$(MAKE) clear-static
	$(MAKE) compile
	$(MAKE) static
	$(MAKE) cache
	$(MAKE) permissions

# -----------------------------
# Diagnostics
# -----------------------------
validate:
	$(COMPOSE) config --quiet

config:
	$(COMPOSE) config

# -----------------------------
# Reset / cleanup
# -----------------------------
reset:
	@echo "Full Docker/project reset..."
	$(COMPOSE) down -v --remove-orphans --rmi local
	docker container prune -f --filter "label=com.docker.compose.project=magento2"
	docker volume prune -f --filter "label=com.docker.compose.project=magento2"
	@if [ "$(OS)" = "Linux" ] && [ "$(LINUX_DISTRO)" = "ubuntu" ] && command -v systemctl >/dev/null 2>&1; then \
		echo "Restarting Docker daemon on Ubuntu..."; \
		sudo systemctl restart docker; \
	else \
		echo "Skipping Docker daemon restart ($(OS) $(LINUX_DISTRO))"; \
	fi
	rm -rf data/db/data \
		data/logs \
		data/opensearch \
		data/redis \
		data/rabbitmq
	rm -rf $(APP_PATH)/var/cache \
		$(APP_PATH)/var/page_cache \
		$(APP_PATH)/var/di \
		$(APP_PATH)/var/view_preprocessed \
		$(APP_PATH)/generated \
		$(APP_PATH)/pub/static/*
	rm -f $(APP_PATH)/app/etc/env.php \
		$(APP_PATH)/app/etc/config.php
	@echo "Project reset completed"
