FROM php:8.3-fpm
RUN apt-get update && apt-get install -y git unzip libpq-dev libzip-dev libicu-dev libonig-dev && docker-php-ext-install pdo pdo_pgsql intl zip
COPY --from=composer:2 /usr/bin/composer /usr/bin/composer
WORKDIR /var/www/backend
COPY ./skeleton/ ./
RUN chmod +x ./ops/bootstrap.sh
EXPOSE 9000
CMD ["sh","-lc","./ops/bootstrap.sh && php-fpm"]
