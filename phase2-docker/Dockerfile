# ==========================================
# STAGE 1: COMPOSER BUILDER
# ==========================================
FROM composer:2.6 as vendor-builder

WORKDIR /app

# Copy dependency files first to leverage Docker layer cache
# (Simulating Laravel composer files)
# COPY composer.json composer.lock ./
# RUN composer install --no-ansi --no-dev --no-interaction --no-plugins --no-progress --no-scripts --optimize-autoloader

# For this demo app, we'll skip actual Composer installation since there's no composer.json.
# We mimic the code copy.
COPY ./app ./app


# ==========================================
# STAGE 2: PRODUCTION RUNTIME (PHP-FPM)
# ==========================================
FROM php:8.2-fpm-alpine as production

# Install essential system dependencies and PHP extensions
RUN apk add --no-cache \
    libpng-dev \
    libjpeg-turbo-dev \
    freetype-dev \
    zip \
    libzip-dev \
    unzip \
    && docker-php-ext-configure gd --with-freetype --with-jpeg \
    && docker-php-ext-install -j$(nproc) gd pdo_mysql zip opcache

# Set up Production PHP Configuration (Opcache is critical in MNC setups)
RUN mv "$PHP_INI_DIR/php.ini-production" "$PHP_INI_DIR/php.ini"
COPY <<EOF /usr/local/etc/php/conf.d/opcache.ini
[opcache]
opcache.enable=1
opcache.enable_cli=1
opcache.memory_consumption=128
opcache.interned_strings_buffer=8
opcache.max_accelerated_files=10000
opcache.validate_timestamps=0
opcache.save_comments=1
EOF

WORKDIR /var/www/html

# Copy application files from the builder stage
COPY --from=vendor-builder --chown=www-data:www-data /app/app .
# Copy our simulator index.php to the root
COPY --chown=www-data:www-data ./app/index.php /var/www/html/index.php

# Security Hardening: Switch to Non-Root User
USER www-data

# Expose PHP-FPM Port
EXPOSE 9000

CMD ["php-fpm"]
