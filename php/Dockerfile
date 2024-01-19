# 使用官方的 PHP 镜像作为基础镜像，选择 PHP 8.1 版本
FROM php:8.0.10-fpm

# # 安装系统依赖
RUN apt-get update && apt-get install -y \
    libzip-dev \
    libsodium-dev \
    libpng-dev \
    unzip && \
    rm -rf /var/lib/apt/lists/*

# # 安装 PHP 扩展
RUN /usr/local/bin/docker-php-ext-install gd pdo pdo_mysql sodium zip

# 安装 Composer v2
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer --version=2.1.8

# 创建 Laravel 项目目录并进入
WORKDIR /var/www

COPY app /var/www/

# # 切换到非root用户
USER www-data

# 暴露 PHP-FPM 端口
EXPOSE 8000

# 启动 PHP-FPM
CMD ["php", "artisan", "serve", "--host=0.0.0.0"]