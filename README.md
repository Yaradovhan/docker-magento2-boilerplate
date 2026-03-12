# Magento 2 Docker
## PHP 8.4 | MariaDB 10.6 | OpenSearch 2.x | Redis 7.4 | RabbitMQ 3.13 | Node 22 | Nginx | Xdebug | Mailpit

---

### Stack

| Service    | Version          | Port(s)      |
|------------|------------------|--------------|
| PHP-FPM    | 8.4              | 9000         |
| Nginx      | latest           | 80           |
| MariaDB    | 10.6             | 3306         |
| OpenSearch | 2.19             | 9200         |
| Redis      | 7.4              | 6379         |
| RabbitMQ   | 3.13 (mgmt)     | 5672 / 15672 |
| Node.js    | 22 LTS           | —            |
| Mailpit    | latest           | 8025         |
| Xdebug     | latest (port 9003) | —          |

### Setup

1. Clone the repository:
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

### Xdebug

Xdebug is pre-configured and active:
- **IDE key**: `PHPSTORM`
- **Port**: `9003`
- **Mode**: `debug,develop`

In PHPStorm: Settings → PHP → Servers → add `docker.m2.loc`, map `/var/www/html` to the `application` folder.

### RabbitMQ Management

Open `http://localhost:15672` — login: `magento` / `magento`

### Mailpit

Open `http://localhost:8025` to view captured emails.

### CLI shortcut — `bin/m2`

Instead of `docker compose exec app bin/magento ...` use the `bin/m2` wrapper:

```bash
bin/m2 <magento-command>        # → bin/magento <command>
bin/m2 composer <args>          # → composer <args>
bin/m2 bash                     # → open shell in container
bin/m2 node / npm <args>        # → node / npm inside container
```

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
