# Magento 2 Local Environment

Minimal local Magento 2 setup driven through `make`.

## What is configured through `.env`

Copy `.env.example` to `.env` and set only what is needed:

- `DOMAIN`  
  Local project domain
- `COMPOSE_PROJECT_NAME`  
  Docker Compose project name used to namespace containers, volumes, and networks
- `APP_PATH`  
  Directory mounted into the app container. Default: `application`
- `GITHUB_REPO`  
  Repository to clone when using `make clone-repo` or `make setup`
- `APP_TIMEZONE`
- `MARIADB_*`
- `ADMIN_*`
- ports for Nginx, Mailpit, phpMyAdmin, Redis, RabbitMQ, OpenSearch

## Prerequisites

- Docker
- `mkcert`
- local hosts entry for your project domain

Install `mkcert`:

```bash
brew install mkcert
```

## Setup flow

1. Create local config:

```bash
cp .env.example .env
```

2. Update `.env` with your project values.

```env
COMPOSE_PROJECT_NAME=myproject
DOMAIN=my-project.loc
GITHUB_REPO=https://github.com/your-org/your-magento-repo.git
```

3. Add the domain from `.env` to `/etc/hosts`:

```bash
echo "127.0.0.1 my-project.loc" | sudo tee -a /etc/hosts
```

Replace `my-project.loc` with your actual domain from `.env`.

4. Run the full setup:

```bash
make full-setup
```

### Alternative: run step by step

Use this if you do not want the full flow in one command.

#### Existing Magento repository

Use this when `GITHUB_REPO` points to a Magento project repository.

```bash
make setup
make hosts
make install
make post-install
```

#### Fresh Magento project

Use this when you want Magento created from scratch instead of cloning a project repository.

```bash
make init
make hosts
make ssl
make up
make create-project
make install
make post-install
```

## Main commands

```bash
make setup
make full-setup
make clone-repo
make composer-install
make create-project
make install
make post-install
make cache
make reindex
make compile
make static
make rebuild
make logs
make down
make reset
```

## URLs

- Storefront: `https://<your-domain>`
- Admin: `https://<your-domain>/admin`
- Mailpit: `http://localhost:8025`
- phpMyAdmin: `http://localhost:8080`
- OpenSearch Dashboards: `http://localhost:5601`
- RabbitMQ: `http://localhost:15672`

## Notes

- `make setup` is for repository-based projects.
- `make create-project` is for a fresh Magento installation.
- If `application` already exists but is empty, `make clone-repo` now recreates it correctly.
- `composer-install` runs inside the mounted Magento root (`/var/www/html`).
- PhpStorm may auto-detect `application` as a nested Git root because it contains its own `.git`. If that happens, go to `Settings -> Version Control` and remove the VCS mapping for `application`.

## Stack

| Service               | Version / Image                                  |
|-----------------------|--------------------------------------------------|
| Magento               | Community Edition                                |
| PHP-FPM               | `php:8.2-fpm`                                    |
| Nginx                 | `nginx:latest`                                   |
| MariaDB               | `mariadb:10.6`                                   |
| OpenSearch            | `opensearchproject/opensearch:2.19.1`            |
| OpenSearch Dashboards | `opensearchproject/opensearch-dashboards:2.19.1` |
| Redis                 | `redis:7.4-alpine`                               |
| RabbitMQ              | `rabbitmq:3.13-management-alpine`                |
| Mailpit               | `axllent/mailpit:latest`                         |
| phpMyAdmin            | `phpmyadmin:latest`                              |
| Node.js               | 22 LTS                                           |
