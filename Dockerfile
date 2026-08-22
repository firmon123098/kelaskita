FROM php:8.2-apache

RUN apt-get update && apt-get install -y \
    git \
    unzip \
    libzip-dev \
    libpng-dev \
    libjpeg62-turbo-dev \
    libfreetype6-dev \
    libonig-dev \
    && docker-php-ext-configure gd --with-freetype --with-jpeg \
    && docker-php-ext-install pdo_mysql mbstring exif pcntl bcmath gd zip \
    && a2enmod rewrite \
    && rm -rf /var/lib/apt/lists/*

COPY --from=composer:2 /usr/bin/composer /usr/bin/composer

WORKDIR /var/www/html

COPY . .

RUN mkdir -p storage/framework/cache storage/framework/sessions storage/framework/views storage/logs bootstrap/cache

RUN composer install --no-dev --optimize-autoloader --no-interaction

ENV APACHE_DOCUMENT_ROOT=/var/www/html/public
RUN sed -ri -e 's!/var/www/html!${APACHE_DOCUMENT_ROOT}!g' /etc/apache2/sites-available/*.conf \
    && sed -ri -e 's!/var/www/!${APACHE_DOCUMENT_ROOT}!g' /etc/apache2/apache2.conf /etc/apache2/conf-available/*.conf

RUN chown -R www-data:www-data storage bootstrap/cache \
    && chmod -R 775 storage bootstrap/cache

RUN printf '#!/bin/bash\nset -x\ncd /var/www/html\nif [ ! -f .env ]; then cp .env.example .env; fi\nif [ -z "$APP_KEY" ]; then php artisan key:generate --force; fi\necho "Running migrations..."\nphp artisan migrate --force\necho "Migration exit code: $?"\nphp artisan config:clear\nphp artisan storage:link || true\nPORT_TO_USE=${PORT:-80}\necho "Using port: $PORT_TO_USE"\nsed -i "s/Listen 80/Listen $PORT_TO_USE/" /etc/apache2/ports.conf\nsed -i "s/:80>/:$PORT_TO_USE>/" /etc/apache2/sites-available/000-default.conf\necho "Starting apache..."\nexec apache2-foreground\n' > /entrypoint.sh \
    && chmod +x /entrypoint.sh

EXPOSE 80

ENTRYPOINT ["/entrypoint.sh"]
