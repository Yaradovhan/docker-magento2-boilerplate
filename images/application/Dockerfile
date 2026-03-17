ARG PHP_VERSION=8.2
FROM php:${PHP_VERSION}-fpm

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
        opcache

# Xdebug
RUN pecl install xdebug && docker-php-ext-enable xdebug

# Node.js (LTS)
RUN curl -fsSL https://deb.nodesource.com/setup_22.x | bash - \
    && apt-get install -y nodejs

# Composer
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

WORKDIR /var/www/html

CMD ["php-fpm"]
