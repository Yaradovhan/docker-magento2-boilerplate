# Magento 2 Docker

Local Magento 2 development environment with PHP 8.2, MariaDB 10.6, OpenSearch 2.19, Redis 7.4, RabbitMQ 3.13, Nginx, Node 22, Xdebug, SPX, Mailpit, and phpMyAdmin.

The environment is designed around `docker compose`, `make`, and the `bin/m2` helper for daily development tasks.

---

## Stack

| Service               | Image / Version                                  | Port(s)         | Container                  |
|-----------------------|--------------------------------------------------|-----------------|----------------------------|
| PHP-FPM               | `php:8.2-fpm`                                    | 9000 (internal) | `m2_app`                   |
| Nginx                 | `nginx:latest`                                   | 80              | `m2_nginx`                 |
| MariaDB               | `mariadb:10.6`                                   | 3306            | `m2_mariadb`               |
| OpenSearch            | `opensearchproject/opensearch:2.19.1`            | 9200, 9600      | `m2_opensearch`            |
| OpenSearch Dashboards | `opensearchproject/opensearch-dashboards:2.19.1` | 5601            | `m2_opensearch_dashboards` |
| Redis                 | `redis:7.4-alpine`                               | 6379            | `m2_redis`                 |
| RabbitMQ              | `rabbitmq:3.13-management-alpine`                | 5672 / 15672    | `m2_rabbitmq`              |
| Mailpit               | `axllent/mailpit:latest`                         | 8025 / 1025     | `m2_mail`                  |
| phpMyAdmin            | `phpmyadmin:latest`                              | 8080            | `m2_phpmyadmin`            |
| Xdebug                | latest                                           | 9003            | —                          |
| SPX Profiler          | latest (compiled from source)                    | —               | —                          |
| Node.js               | 22 LTS                                           | —               | —                          |
| Composer              | latest                                           | —               | —                          |

> All ports are configurable via `.env`.

---

## Requirements

- Docker
- Docker Compose
- Free ports: `80`, `1025`, `3306`, `5601`, `5672`, `6379`, `8025`, `8080`, `9200`, `15672`

---

## Quick Start

1. Clone the repository and create `.env`:
   ```
   git clone <repo-url> .
   cp .env.example .env
   ```

2. Add the local domain to `/etc/hosts`:
   ```
   echo "127.0.0.1 docker.m2.loc" | sudo tee -a /etc/hosts
   ```

3. Build and start the containers:
   ```
   make setup
   ```

4. Create Magento 2 inside the `application` directory:
   ```
   make create-project
   ```

5. Install Magento:
   ```
   make install
   ```

6. Apply post-install dev setup:
   ```
   make post-install
   ```

7. Open the project in your browser:
   ```
   http://docker.m2.loc
   ```

---

## Daily Usage

### Start environment
```
make up
```

### Stop environment
```
make stop
```

### Restart environment
```
make restart
```

### Show container status
```
make ps
```

### Open shell in app container
```
make shell
```

### Show all logs
```
make logs
```

### Show app logs only
```
make logs-app
```

---

## Magento Commands

### Run Magento CLI
```
make m2 ARGS='cache:flush'
make m2 ARGS='indexer:reindex'
make m2 ARGS='setup:upgrade'
```

### Run Composer
```
make composer ARGS='install'
make composer ARGS='require vendor/package'
```

### Run Node / npm
```
make node ARGS='-v'
make npm ARGS='run build'
```

### Common Magento targets
```
make cache
make reindex
make compile
make static
make upgrade
make deploy-mode-dev
make permissions
make rebuild
```

---

## Makefile Commands

### Main
```
make setup
make create-project
make install
make post-install
make reinstall
make reset
```

### Containers
```
make build
make up
make start
make stop
make restart
make down
make clean
make pull
make ps
make status
make logs
make logs-app
make logs-nginx
make logs-db
make shell
make root-shell
```

### Magento
```
make m2 ARGS='cache:flush'
make composer ARGS='install'
make composer-i
make cache
make reindex
make compile
make static
make upgrade
make deploy-mode-dev
make sample-data
```

### Diagnostics / maintenance
```
make validate
make config
make permissions
make clear-static
make rebuild
make reset
```

---

## Magento Installation Parameters

`make install` runs `bin/magento setup:install` with the following defaults:

```
--base-url=http://docker.m2.loc
--backend-frontname=admin
--db-host=mariadb
--db-name=magento
--db-user=magento
--db-password=magento
--admin-firstname=Admin
--admin-lastname=Admin
--admin-email=admin@example.com
--admin-user=admin
--admin-password=admin123
--language=en_US
--currency=USD
--timezone=Europe/Kyiv
--use-rewrites=1
--search-engine=opensearch
--opensearch-host=opensearch
--opensearch-port=9200
--session-save=redis
--session-save-redis-host=redis
--session-save-redis-port=6379
--session-save-redis-db=2
--cache-backend=redis
--cache-backend-redis-server=redis
--cache-backend-redis-port=6379
--cache-backend-redis-db=0
--page-cache=redis
--page-cache-redis-server=redis
--page-cache-redis-port=6379
--page-cache-redis-db=1
--amqp-host=rabbitmq
--amqp-port=5672
--amqp-user=magento
--amqp-password=magento
```

After installation, `make post-install` performs:

```
bin/magento module:disable Magento_AdminAdobeImsTwoFactorAuth Magento_TwoFactorAuth
bin/magento setup:upgrade
bin/magento deploy:mode:set developer
bin/magento cache:flush
```

---

## Web Interfaces

| Service               | URL                        | Credentials           |
|-----------------------|----------------------------|-----------------------|
| Magento Storefront    | http://docker.m2.loc       | —                     |
| Magento Admin         | http://docker.m2.loc/admin | `admin` / `admin123`  |
| phpMyAdmin            | http://localhost:8080      | auto-login via env    |
| OpenSearch Dashboards | http://localhost:5601      | —                     |
| RabbitMQ Management   | http://localhost:15672     | `magento` / `magento` |
| Mailpit               | http://localhost:8025      | —                     |

---

## Environment Variables

All configuration is stored in `.env`:

| Variable                      | Default             | Description                |
|------------------------------|---------------------|----------------------------|
| `APP_TIMEZONE`               | `Europe/Kyiv`       | PHP timezone               |
| `PHP_VERSION`                | `8.2`               | PHP version for app        |
| `NGINX_PORT`                 | `80`                | Nginx HTTP port            |
| `MARIADB_PORT`               | `3306`              | MariaDB port               |
| `MARIADB_ROOT_PASSWORD`      | `root`              | MariaDB root password      |
| `MARIADB_DATABASE`           | `magento`           | Database name              |
| `MARIADB_USER`               | `magento`           | Database user              |
| `MARIADB_PASSWORD`           | `magento`           | Database password          |
| `OPENSEARCH_PORT`            | `9200`              | OpenSearch HTTP port       |
| `OPENSEARCH_JAVA_OPTS`       | `-Xms512m -Xmx512m` | OpenSearch JVM memory      |
| `OPENSEARCH_DASHBOARDS_PORT` | `5601`              | Dashboards port            |
| `REDIS_PORT`                 | `6379`              | Redis port                 |
| `RABBITMQ_PORT`              | `5672`              | RabbitMQ AMQP port         |
| `RABBITMQ_MANAGEMENT_PORT`   | `15672`             | RabbitMQ management port   |
| `RABBITMQ_DEFAULT_USER`      | `magento`           | RabbitMQ user              |
| `RABBITMQ_DEFAULT_PASS`      | `magento`           | RabbitMQ password          |
| `MAILPIT_UI_PORT`            | `8025`              | Mailpit web UI port        |
| `MAILPIT_SMTP_PORT`          | `1025`              | Mailpit SMTP port          |
| `PHPMYADMIN_PORT`            | `8080`              | phpMyAdmin port            |

---

## CLI Shortcut: `bin/m2`

`bin/m2` is a wrapper for running commands inside the `app` container:

```
bin/m2 <magento-command>        # runs bin/magento <command>
bin/m2 composer <args>          # runs composer <args>
bin/m2 bash                     # opens shell in container
bin/m2 node <args>              # runs node inside container
bin/m2 npm <args>               # runs npm inside container
```

### Examples
```
bin/m2 indexer:reindex
bin/m2 cache:flush
bin/m2 setup:di:compile
bin/m2 setup:static-content:deploy -f
bin/m2 queue:consumers:start
bin/m2 composer require vendor/package
bin/m2 bash
```

---

## Xdebug

Xdebug is pre-configured and starts automatically with every request.

| Setting           | Value                  |
|-------------------|------------------------|
| Mode              | `debug,develop`        |
| Port              | `9003`                 |
| IDE Key           | `PHPSTORM`             |
| Client Host       | `host.docker.internal` |
| Max Nesting Level | `512`                  |

**PHPStorm setup:**  
Go to `Settings → PHP → Servers`, add server `docker.m2.loc`, and map project root `/var/www/html` to local `application`.

---

## SPX Profiler

[SPX](https://github.com/NoiseByNorthworst/php-spx) is installed and enabled for performance profiling.

Enable profiling by adding these query params to any URL:

```
?SPX_KEY=dev&SPX_ENABLED=1
```

SPX UI:

```
http://docker.m2.loc/?SPX_KEY=dev&SPX_UI_URI=/
```

---

## PHP Configuration

| Setting                         | Value     |
|---------------------------------|-----------|
| `memory_limit`                  | `-1`      |
| `max_execution_time`            | `300`     |
| `max_input_vars`                | `2786`    |
| `upload_max_filesize`           | `240M`    |
| `post_max_size`                 | `240M`    |
| `opcache.memory_consumption`    | `256M`    |
| `opcache.max_accelerated_files` | `40000`   |
| `opcache.validate_timestamps`   | `1`       |
| `opcache.revalidate_freq`       | `0`       |
| `realpath_cache_size`           | `16384K`  |
| `realpath_cache_ttl`            | `1800`    |

---

## MariaDB Tuning

Custom settings are stored in `images/mariadb/my.cnf`:

| Setting                          | Value   |
|----------------------------------|---------|
| `innodb_buffer_pool_size`        | `4G`    |
| `tmp_table_size`                 | `256M`  |
| `max_heap_table_size`            | `256M`  |
| `sort_buffer_size`               | `8M`    |
| `join_buffer_size`               | `8M`    |
| `max_allowed_packet`             | `256M`  |
| `innodb_log_file_size`           | `256M`  |
| `innodb_flush_log_at_trx_commit` | `2`     |
| `innodb_flush_method`            | `O_DIRECT` |

---

## Data Volumes

Persistent data is stored in the `data/` directory:

| Path              | Service      |
|-------------------|--------------|
| `data/db/data`    | MariaDB      |
| `data/logs`       | MariaDB logs |
| `data/opensearch` | OpenSearch   |
| `data/redis`      | Redis        |
| `data/rabbitmq`   | RabbitMQ     |
| `data/share`      | Shared data  |

---

## Reset and Recovery

### Full environment reset
```
make reset
```

This target:
- stops and removes containers, volumes, and orphans
- removes project data from `data/`
- clears Magento generated/cache/static artifacts
- removes `application/app/etc/env.php`
- removes `application/app/etc/config.php`
- restarts Docker daemon automatically on Ubuntu if needed

### Reinstall Magento only
```
make reinstall
```

### Rebuild static/dev artifacts
```
make rebuild
```

---

## Notes

- `make` is the preferred entry point for routine project management.
- `bin/m2` is useful for day-to-day Magento commands inside the container.
- `docker compose` can still be used directly for advanced or custom workflows.
