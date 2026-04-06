# Magento 2 Docker

Local Magento 2 development environment with PHP 8.2, MariaDB 10.6, OpenSearch 2.19, Redis 7.4, RabbitMQ 3.13, Nginx, Node 22, Xdebug, SPX, Mailpit, and phpMyAdmin.

The main workflow is based on `make`, with `docker compose` and `bin/m2` available for lower-level commands.

---

## Stack

| Service               | Version / Image                                  | URL / Port                  |
|-----------------------|--------------------------------------------------|-----------------------------|
| Magento               | Community Edition                                | https://docker.m2.loc       |
| PHP-FPM               | `php:8.2-fpm`                                    | 9000 internal               |
| Nginx                 | `nginx:latest`                                   | 80 / 443                    |
| MariaDB               | `mariadb:10.6`                                   | 3306                        |
| OpenSearch            | `opensearchproject/opensearch:2.19.1`            | 9200 / 9600                 |
| OpenSearch Dashboards | `opensearchproject/opensearch-dashboards:2.19.1` | http://localhost:5601       |
| Redis                 | `redis:7.4-alpine`                               | 6379                        |
| RabbitMQ              | `rabbitmq:3.13-management-alpine`                | http://localhost:15672      |
| Mailpit               | `axllent/mailpit:latest`                         | http://localhost:8025       |
| phpMyAdmin            | `phpmyadmin:latest`                              | http://localhost:8080       |
| Node.js               | 22 LTS                                           | inside app container        |
| Composer              | latest                                           | inside app container        |
| Xdebug                | latest                                           | 9003                        |
| SPX                   | latest                                           | Magento URL query params    |

---

## Requirements

- Docker
- Docker Compose
- Homebrew
- mkcert
- Free ports: `80`, `443`, `1025`, `3306`, `5601`, `5672`, `6379`, `8025`, `8080`, `9200`, `15672`

If `80` or `443` are already used by another local stack, update `NGINX_PORT` and `NGINX_SSL_PORT` in `.env`.

---

## Quick Start

1. Clone the repository and create `.env`:

```bash
git clone <repo-url> .
cp .env.example .env
```

2. Add the local domain to `/etc/hosts`:

```bash
echo "127.0.0.1 docker.m2.loc" | sudo tee -a /etc/hosts
```

3. Install mkcert:

```bash
brew install mkcert
```

4. Start the environment and generate local SSL certificates:

```bash
make setup
```

5. Create Magento 2 inside the `application` directory:

```bash
make create-project
```

6. Install Magento:

```bash
make install
```

7. Apply post-install setup:

```bash
make post-install
```

8. Open Magento:

```text
https://docker.m2.loc
```

---

## Local HTTPS

The project uses local HTTPS through `mkcert`.

Certificates are expected here:

```text
images/application/nginx/certs/docker.m2.loc.pem
images/application/nginx/certs/docker.m2.loc-key.pem
```

The easiest way to generate local certificates is:

```bash
make ssl
```

Manual certificate generation:

```bash
brew install mkcert
mkcert -install

mkdir -p images/application/nginx/certs

mkcert \
-cert-file images/application/nginx/certs/docker.m2.loc.pem \
-key-file images/application/nginx/certs/docker.m2.loc-key.pem \
docker.m2.loc localhost 127.0.0.1 ::1
```

The `certs` directory is kept in git with `.gitkeep`, but generated certificates are ignored and should not be committed.

If port `443` is busy, use another local HTTPS port in `.env`:

```env
NGINX_SSL_PORT=8443
```

Then use:

```text
https://docker.m2.loc:8443
```

After changing HTTPS settings, update Magento secure URLs:

```bash
make ssl-config
```

Manual secure URL configuration:

```bash
docker compose exec app php bin/magento config:set web/secure/base_url https://docker.m2.loc/
docker compose exec app php bin/magento config:set web/secure/use_in_frontend 1
docker compose exec app php bin/magento config:set web/secure/use_in_adminhtml 1
docker compose exec app php bin/magento cache:flush
```

For custom HTTPS ports, include the port in `web/secure/base_url`, for example:

```bash
docker compose exec app php bin/magento config:set web/secure/base_url https://docker.m2.loc:8443/
```

---

## Main Commands

### Environment

```bash
make setup
make up
make stop
make restart
make down
make ps
make status
make logs
make logs-app
make logs-nginx
make logs-db
```

### Magento

```bash
make create-project
make install
make post-install
make upgrade
make cache
make reindex
make compile
make static
make deploy-mode-dev
make rebuild
```

### Shell and tools

```bash
make shell
make root-shell
make composer ARGS='install'
make composer ARGS='require vendor/package'
make npm ARGS='run build'
make node ARGS='-v'
make m2 ARGS='cache:flush'
```

### Maintenance

```bash
make permissions
make clear-static
make validate
make config
make reset
```

---

## Web Interfaces

| Service               | URL                         | Credentials           |
|-----------------------|-----------------------------|-----------------------|
| Magento Storefront    | https://docker.m2.loc       | —                     |
| Magento Admin         | https://docker.m2.loc/admin | `admin` / `admin123`  |
| phpMyAdmin            | http://localhost:8080       | auto-login via env    |
| OpenSearch Dashboards | http://localhost:5601       | —                     |
| RabbitMQ Management   | http://localhost:15672      | `magento` / `magento` |
| Mailpit               | http://localhost:8025       | —                     |

---

## Local Mail

Mailpit is used for local email testing.

Mailpit UI:

```text
http://localhost:8025
```

SMTP inside Docker:

```text
host: mail
port: 1025
```

The PHP app container sends mail through `msmtp` to Mailpit.

If using Mageplaza SMTP locally, configure it as:

```text
Host: mail
Port: 1025
Protocol: None
Authentication: None
Username:
Password:
```

---

## Environment Variables

The main settings are stored in `.env`.

| Variable                      | Default             | Description              |
|------------------------------|---------------------|--------------------------|
| `APP_TIMEZONE`               | `Europe/Kyiv`       | PHP timezone             |
| `PHP_VERSION`                | `8.2`               | PHP version              |
| `NGINX_PORT`                 | `80`                | Nginx HTTP port          |
| `NGINX_SSL_PORT`             | `443`               | Nginx HTTPS port         |
| `MARIADB_PORT`               | `3306`              | MariaDB port             |
| `MARIADB_ROOT_PASSWORD`      | `root`              | MariaDB root password    |
| `MARIADB_DATABASE`           | `magento`           | Database name            |
| `MARIADB_USER`               | `magento`           | Database user            |
| `MARIADB_PASSWORD`           | `magento`           | Database password        |
| `OPENSEARCH_PORT`            | `9200`              | OpenSearch HTTP port     |
| `OPENSEARCH_JAVA_OPTS`       | `-Xms512m -Xmx512m` | OpenSearch memory        |
| `OPENSEARCH_DASHBOARDS_PORT` | `5601`              | Dashboards port          |
| `REDIS_PORT`                 | `6379`              | Redis port               |
| `RABBITMQ_PORT`              | `5672`              | RabbitMQ AMQP port       |
| `RABBITMQ_MANAGEMENT_PORT`   | `15672`             | RabbitMQ management port |
| `RABBITMQ_DEFAULT_USER`      | `magento`           | RabbitMQ user            |
| `RABBITMQ_DEFAULT_PASS`      | `magento`           | RabbitMQ password        |
| `MAILPIT_UI_PORT`            | `8025`              | Mailpit UI port          |
| `MAILPIT_SMTP_PORT`          | `1025`              | Mailpit SMTP port        |
| `PHPMYADMIN_PORT`            | `8080`              | phpMyAdmin port          |

---

## bin/m2 Shortcut

`bin/m2` is a helper for running commands inside the app container.

```bash
bin/m2 <magento-command>
bin/m2 composer <args>
bin/m2 bash
bin/m2 node <args>
bin/m2 npm <args>
```

Examples:

```bash
bin/m2 cache:flush
bin/m2 indexer:reindex
bin/m2 setup:upgrade
bin/m2 composer require vendor/package
```

---

## Debugging Tools

### Xdebug

Xdebug is enabled with:

| Setting     | Value                  |
|-------------|------------------------|
| Mode        | `debug,develop`        |
| Port        | `9003`                 |
| IDE Key     | `PHPSTORM`             |
| Client Host | `host.docker.internal` |

PHPStorm server:
- name: `docker.m2.loc`
- container path: `/var/www/html`
- local path: `application`

### SPX

SPX is available through URL query params:

```text
https://docker.m2.loc/?SPX_KEY=dev&SPX_UI_URI=/
```

To profile a request:

```text
?SPX_KEY=dev&SPX_ENABLED=1
```

---

## Data and Reset

Persistent data is stored in `data/`.

| Path              | Service      |
|-------------------|--------------|
| `data/db/data`    | MariaDB      |
| `data/logs`       | MariaDB logs |
| `data/opensearch` | OpenSearch   |
| `data/redis`      | Redis        |
| `data/rabbitmq`   | RabbitMQ     |
| `data/share`      | Shared data  |

Full environment reset:

```bash
make reset
```

This removes project containers, project volumes, local service data, Magento generated files, cache/static artifacts, and `application/app/etc/env.php`.

Use carefully.

---

## Notes

- Use `make` for routine project management.
- Use `bin/m2` for quick Magento commands inside the app container.
- Local SSL certificates are generated per machine and must not be committed.
- If HTTPS redirects behave unexpectedly, clear browser site data for `docker.m2.loc` or test in an incognito window.
- Advanced PHP and MariaDB tuning lives in `images/application/usr/local/etc/php/conf.d/` and `images/mariadb/my.cnf`.
