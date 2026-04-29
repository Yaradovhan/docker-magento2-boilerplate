ARG PHP_VERSION=8.2
FROM php:${PHP_VERSION}-fpm

# -----------------------------
# System packages + PHP extensions
# -----------------------------
RUN apt-get update && apt-get install -y \
    libicu-dev \
    libpng-dev \
    libjpeg-dev \
    libfreetype6-dev \
    libonig-dev \
    libxml2-dev \
    libxslt1-dev \
    libzip-dev \
    libsodium-dev \
    unzip \
    curl \
    gnupg \
    ca-certificates \
    git \
    msmtp \
    msmtp-mta \
    && docker-php-ext-configure gd --with-freetype --with-jpeg \
    && docker-php-ext-install \
        bcmath \
        ctype \
        dom \
        gd \
        intl \
        mbstring \
        pdo \
        pdo_mysql \
        simplexml \
        soap \
        sockets \
        sodium \
        xsl \
        zip \
        ftp \
        opcache \
    && rm -rf /var/lib/apt/lists/*

# -----------------------------
# Xdebug
# -----------------------------
RUN pecl install xdebug \
    && docker-php-ext-enable xdebug

# -----------------------------
# SPX profiler
# -----------------------------
RUN apt-get update && apt-get install -y zlib1g-dev \
    && cd /tmp \
    && git clone https://github.com/NoiseByNorthwest/php-spx.git \
    && cd php-spx \
    && phpize \
    && ./configure \
    && make \
    && make install \
    && docker-php-ext-enable spx \
    && rm -rf /tmp/php-spx \
    && rm -rf /var/lib/apt/lists/*

# -----------------------------
# Node.js
# -----------------------------
RUN curl -fsSL https://deb.nodesource.com/setup_22.x | bash - \
    && apt-get install -y nodejs \
    && rm -rf /var/lib/apt/lists/*

# -----------------------------
# Composer
# -----------------------------
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

# -----------------------------
# Mailpit / SMTP via msmtp
# -----------------------------
COPY msmtprc.template /etc/msmtprc.template
RUN chmod 644 /etc/msmtprc.template

COPY docker-entrypoint.sh /docker-entrypoint.sh
RUN chmod +x /docker-entrypoint.sh

# -----------------------------
# Working directory
# -----------------------------
WORKDIR /var/www/html

ENTRYPOINT ["/docker-entrypoint.sh"]
CMD ["php-fpm"]
