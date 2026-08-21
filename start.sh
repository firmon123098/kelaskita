#!/bin/sh
set -e

# Generate app key if not already set
if [ -z "$APP_KEY" ]; then
  php artisan key:generate --force
fi

# Cache config for performance
php artisan config:cache || true

# Run database migrations (safe to run every deploy)
php artisan migrate --force

# Start the server on the port Railway provides
php artisan serve --host=0.0.0.0 --port=${PORT:-8000}
