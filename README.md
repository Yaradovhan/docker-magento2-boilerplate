# Magento 2 Docker

## PHP 8.2 | MariaDB 10.6 | OpenSearch 2.19 | Redis 7.4 | RabbitMQ 3.13 | Nginx | Node 22 | Xdebug | SPX | Mailpit | phpMyAdmin

---

### Stack

| Service              | Image / Version                          | Port(s)        | Container        |
|----------------------|------------------------------------------|----------------|------------------|
| PHP-FPM              | `php:8.2-fpm`                            | 9000 (internal) | `m2_app`        |
| Nginx                | `nginx:latest`                           | 80             | `m2_nginx`       |
| MariaDB              | `mariadb:10.6`                           | 3306           | `m2_mariadb`     |
| OpenSearch           | `opensearchproject/opensearch:2.19.1`    | 9200, 9600     | `m2_opensearch`  |
| OpenSearch Dashboards| `opensearchproject/opensearch-dashboards:2.19.1` | 5601   | `m2_opensearch_dashboards` |
| Redis                | `redis:7.4-alpine`                       | 6379           | `m2_redis`       |
| RabbitMQ             | `rabbitmq:3.13-management-alpine`        | 5672 / 15672   | `m2_rabbitmq`    |
| Mailpit              | `axllent/mailpit:latest`                 | 8025 / 1025    | `m2_mail`        |
| phpMyAdmin           | `phpmyadmin:latest`                      | 8080           | `m2_phpmyadmin`  |
| Xdebug               | latest                                   | 9003           | —                |
| SPX Profiler         | latest (compiled from source)            | —              | —                |
| Node.js              | 22 LTS                                   | —              | —                |
| Composer             | latest                                   | —              | —                |

> All ports are configurable via `.env` file.

---

### Requirements

- Docker & Docker Compose
- Free ports: 80, 1025, 3306, 5601, 5672, 6379, 8025, 8080, 9200, 15672

---

### Setup

1. Clone the repository and create `.env`:
   ```bash
   git clone <repo-url> . && cp .env.example .env
   ```

2. Add domain to `/etc/hosts`:
   ```bash
   echo "127.0.0.1 docker.m2.loc" | sudo tee -a /etc/hosts
   ```

3. Build and start containers:
   ```bash
   docker compose up -d --build
   ```

4. Create Magento 2 project inside the `application` folder:
   ```bash
   bin/m2 composer create-project --repository-url=https://repo.magento.com/ magento/project-community-edition .
   ```

5. Install Magento:
   ```bash
   bin/m2 setup:install \
     --base-url=http://docker.m2.loc \
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
   ```

6. Disable Two-Factor Auth and set developer mode:
   ```bash
   bin/m2 module:disable Magento_AdminAdobeImsTwoFactorAuth Magento_TwoFactorAuth
   bin/m2 setup:upgrade
   bin/m2 deploy:mode:set developer
   bin/m2 cache:flush
   ```

7. Open `http://docker.m2.loc` in your browser.

---

### Environment Variables

All settings are in `.env` (copy from `.env.example`):

| Variable                   | Default          | Description                        |
|----------------------------|------------------|------------------------------------|
| `APP_TIMEZONE`             | `Europe/Kyiv`    | PHP timezone                       |
| `PHP_VERSION`              | `8.2`            | PHP version for the app container  |
| `NGINX_PORT`               | `80`             | Nginx HTTP port                    |
| `MARIADB_PORT`             | `3306`           | MariaDB port                       |
| `MARIADB_ROOT_PASSWORD`    | `root`           | MariaDB root password              |
| `MARIADB_DATABASE`         | `magento`        | Database name                      |
| `MARIADB_USER`             | `magento`        | Database user                      |
| `MARIADB_PASSWORD`         | `magento`        | Database password                  |
| `OPENSEARCH_PORT`          | `9200`           | OpenSearch HTTP port               |
| `OPENSEARCH_JAVA_OPTS`     | `-Xms512m -Xmx512m` | OpenSearch JVM memory          |
| `OPENSEARCH_DASHBOARDS_PORT` | `5601`         | OpenSearch Dashboards port         |
| `REDIS_PORT`               | `6379`           | Redis port                         |
| `RABBITMQ_PORT`            | `5672`           | RabbitMQ AMQP port                 |
| `RABBITMQ_MANAGEMENT_PORT` | `15672`          | RabbitMQ Management UI port        |
| `RABBITMQ_DEFAULT_USER`    | `magento`        | RabbitMQ user                      |
| `RABBITMQ_DEFAULT_PASS`    | `magento`        | RabbitMQ password                  |
| `MAILPIT_UI_PORT`          | `8025`           | Mailpit web UI port                |
| `MAILPIT_SMTP_PORT`        | `1025`           | Mailpit SMTP port                  |
| `PHPMYADMIN_PORT`          | `8080`           | phpMyAdmin port                    |

---

### Web Interfaces

| Service              | URL                          | Credentials            |
|----------------------|------------------------------|------------------------|
| Magento Storefront   | http://docker.m2.loc         | —                      |
| Magento Admin        | http://docker.m2.loc/admin   | `admin` / `admin123`   |
| phpMyAdmin           | http://localhost:8080        | auto-login via env     |
| OpenSearch Dashboards| http://localhost:5601        | —                      |
| RabbitMQ Management  | http://localhost:15672       | `magento` / `magento`  |
| Mailpit              | http://localhost:8025        | —                      |

---

### Xdebug

Xdebug is pre-configured and starts automatically with every request.

| Setting              | Value                  |
|----------------------|------------------------|
| Mode                 | `debug,develop`        |
| Port                 | `9003`                 |
| IDE Key              | `PHPSTORM`             |
| Client Host          | `host.docker.internal` |
| Max Nesting Level    | `512`                  |

**PHPStorm setup:** Settings → PHP → Servers → add server `docker.m2.loc`, map project root `/var/www/html` to the `application` folder.

---

### SPX Profiler

[SPX](https://github.com/NoiseByNorthworst/php-spx) is installed and enabled for performance profiling.

To use it, add `?SPX_KEY=dev&SPX_ENABLED=1` to any URL. The profiler UI is available at:
```
http://docker.m2.loc/?SPX_KEY=dev&SPX_UI_URI=/
```

---

### PHP Configuration

| Setting                        | Value       |
|--------------------------------|-------------|
| `memory_limit`                 | `-1` (unlimited) |
| `max_execution_time`           | `300`       |
| `max_input_vars`               | `2786`      |
| `upload_max_filesize`          | `240M`      |
| `post_max_size`                | `240M`      |
| `opcache.memory_consumption`   | `256M`      |
| `opcache.max_accelerated_files`| `40000`     |
| `opcache.validate_timestamps`  | `1`         |
| `opcache.revalidate_freq`      | `0`         |
| `realpath_cache_size`          | `16384K`    |
| `realpath_cache_ttl`           | `1800`      |

---

### MariaDB Tuning

Custom settings in `images/mariadb/my.cnf`:

| Setting                           | Value   |
|-----------------------------------|---------|
| `innodb_buffer_pool_size`         | `4G`    |
| `tmp_table_size`                  | `256M`  |
| `max_heap_table_size`             | `256M`  |
| `sort_buffer_size`                | `8M`    |
| `join_buffer_size`                | `8M`    |
| `max_allowed_packet`              | `256M`  |
| `innodb_log_file_size`            | `256M`  |
| `innodb_flush_log_at_trx_commit`  | `2`     |
| `innodb_flush_method`             | `O_DIRECT` |

---

### CLI shortcut — `bin/m2`

Wrapper script to execute commands inside the `app` container:

```bash
bin/m2 <magento-command>        # → bin/magento <command>
bin/m2 composer <args>          # → composer <args>
bin/m2 bash                     # → open shell in container
bin/m2 node / npm <args>        # → node / npm inside container
```

---

### Useful commands

```bash
# Reindex
bin/m2 indexer:reindex

# Cache flush
bin/m2 cache:flush

# Compile DI
bin/m2 setup:di:compile

# Static content deploy
bin/m2 setup:static-content:deploy -f

# Run consumers
bin/m2 queue:consumers:start

# Composer
bin/m2 composer require vendor/package

# Shell
bin/m2 bash
```

---

### Data Volumes

Persistent data is stored in the `data/` directory:

| Path                | Service        |
|---------------------|----------------|
| `data/db/data`      | MariaDB        |
| `data/logs`         | MariaDB logs   |
| `data/opensearch`   | OpenSearch     |
| `data/redis`        | Redis          |
| `data/rabbitmq`     | RabbitMQ       |
| `data/share`        | Shared data    |
