#!/usr/bin/with-contenv bash

echo '
-------------------------------------
Adjusting UID and GID of nginx
-------------------------------------'
PUID=${PUID:-1000}
PGID=${PGID:-1000}

groupmod -o -g "$PGID" www-data
usermod -o -u "$PUID" -g "$PGID" nginx

echo '
-------------------------------------
GID/UID
-------------------------------------'
echo "
User uid:    $(id -u nginx)
User gid:    $(id -g nginx)
-------------------------------------
"


chown nginx:www-data /etc/nginx -R
chown nginx:www-data /usr/local/etc/php-fpm.conf
chown nginx:www-data /usr/local/etc/php-fpm.d -R
sed -i "s/user = www-data/user = nginx/g" /usr/local/etc/php-fpm.d/www.conf
