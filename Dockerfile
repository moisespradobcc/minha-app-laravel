# --- ESTÁGIO 1: Dependências do Composer ---
FROM composer:2.5 as vendor
WORKDIR /app
COPY database/ database/
COPY composer.json composer.lock ./
RUN composer install --no-interaction --no-dev --optimize-autoloader

# --- ESTÁGIO 2: Aplicação (PHP-FPM) ---
# Usando a versão 8.2 correta
FROM php:8.2-fpm-alpine

WORKDIR /var/www/html

# Instala extensões
RUN apk --no-cache add \
    libzip-dev \
    zip \
    mariadb-client
RUN docker-php-ext-install pdo_mysql zip bcmath

# Copia as dependências do estágio 1
COPY --from=vendor /app/vendor/ /var/www/html/vendor/
# Copia o código da aplicação
COPY . .

# Otimiza o Laravel para produção
RUN php artisan config:cache && \
    php artisan route:cache && \
    php artisan view:cache

# Define permissões
RUN chown -R www-data:www-data /var/www/html/storage /var/www/html/bootstrap/cache
RUN chmod -R 775 /var/www/html/storage /var/www/html/bootstrap/cache

EXPOSE 9000