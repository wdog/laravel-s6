FROM php:8.3.16-fpm-alpine


# Install dependencies
RUN apk add --no-cache \
    s6-overlay bash \
    nginx \
    nodejs npm \
    curl zip unzip shadow openssl \
    oniguruma-dev gpg sqlite-dev \
    libpng-dev libjpeg-turbo-dev icu-dev \
    icu-data-full libzip-dev && \
    docker-php-ext-install pcntl mbstring gd bcmath zip bz2 intl pdo_mysql && \
    docker-php-ext-configure intl && \
    docker-php-ext-configure pcntl --enable-pcntl && \
    rm -rf /var/cache/apk/* && \
    rm -rf /usr/src/php




# -----------
# SQL SERVER
# -----------
ENV ACCEPT_EULA=Y
# Install prerequisites for the sqlsrv and pdo_sqlsrv PHP extensions.
RUN cd /tmp && \
    curl -O https://download.microsoft.com/download/7/6/d/76de322a-d860-4894-9945-f0cc5d6a45f8/msodbcsql18_18.4.1.1-1_amd64.apk && \
    curl -O https://download.microsoft.com/download/7/6/d/76de322a-d860-4894-9945-f0cc5d6a45f8/mssql-tools18_18.4.1.1-1_amd64.apk && \
    apk add --allow-untrusted msodbcsq*.apk && \
    apk add --allow-untrusted mssql-tools*.apk && \
    apk add --no-cache --virtual .phpize-deps $PHPIZE_DEPS unixodbc-dev && \
    pecl channel-update pecl.php.net && \
    pecl install sqlsrv pdo_sqlsrv && \
    docker-php-ext-enable sqlsrv pdo_sqlsrv && \
    apk del .phpize-deps && \
    rm /tmp/*.apk



# create SSL certificate for nginx
RUN openssl req -x509 -nodes -days 365 \
    -subj  "/C=IT/ST=QC/O=Dark Empire/CN=localhost" \
    -newkey rsa:2048 -keyout /etc/ssl/private/nginx.key \
    -out /etc/ssl/certs/nginx.crt;

COPY config/php/php_extra.ini /usr/local/etc/php/conf.d/php_extra.ini
COPY config/nginx/nginx.conf /etc/nginx/nginx.conf
COPY config/nginx/default.conf /etc/nginx/conf.d/default.conf

# Set up s6 services
COPY ./s6-overlay/services.d/ /etc/services.d/
RUN chmod +x /etc/services.d/*/run

COPY ./s6-overlay/cont-init.d/ /etc/cont-init.d/

COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

# Set up working directory
WORKDIR /var/www/html

# Expose ports and start s6
EXPOSE 80 443 5173
ENTRYPOINT ["/init"]
