FROM php:8.3.2-fpm

# Install system dependencies
RUN apt-get update && apt-get install -y \
    git \
    curl \
    libpng-dev \
    libonig-dev \
    libxml2-dev \
    libzip-dev \
    zip \
    unzip

# Clear cache
RUN apt-get clean && rm -rf /var/lib/apt/lists/*

# Get latest Composer
RUN cp /usr/local/etc/php/php.ini-production /usr/local/etc/php/php.ini

# Install PHP extensions
RUN docker-php-source extract && \
    docker-php-ext-install pdo_mysql mbstring exif pcntl bcmath gd zip opcache && \
    docker-php-source delete

# Copy custom FPM configuration
COPY www.conf /usr/local/etc/php-fpm.d/zzz-custom.conf

USER www-data

# Set working directory
WORKDIR /var/www

COPY --from=composer:latest /usr/bin/composer /usr/bin/composer