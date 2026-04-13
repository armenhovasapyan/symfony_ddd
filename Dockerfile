FROM php:8.5-fpm-alpine

# Install system deps
RUN apk add --no-cache \
    git \
    unzip \
    icu-dev \
    libzip-dev \
    libxml2-dev \
    oniguruma-dev \
    libpq-dev \
    $PHPIZE_DEPS

# PHP extensions for Symfony + PostgreSQL, Redis, AMQP (RabbitMQ)
RUN docker-php-ext-configure intl \
 && docker-php-ext-install -j$(nproc) \
    pdo_pgsql \
    intl \
    zip \
    bcmath \
    pcntl \
    xml \
    mbstring

# Remove build-only deps to shrink image (PHPIZE_DEPS = autoconf, g++, make, ...)
RUN apk del $PHPIZE_DEPS 2>/dev/null || true \
    && rm -rf /var/cache/apk/* /tmp/pear

# Composer
COPY --from=composer:2 /usr/bin/composer /usr/bin/composer
ENV COMPOSER_ALLOW_SUPERUSER=1

# Ensure PHP-FPM listens on all interfaces for nginx in another container.
# When building from the project root (context: .), the file lives under
COPY configuration/php-fpm/zzz-listener.conf /usr/local/etc/php-fpm.d/zzz-listener.conf

RUN git config --global --add safe.directory '*'

WORKDIR /var/www/html

# Optional: create Symfony scratch project if no composer.json (run via entrypoint)
COPY docker-entrypoint.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/docker-entrypoint.sh
ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]

EXPOSE 9000
CMD ["php-fpm"]
