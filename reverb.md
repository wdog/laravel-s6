
# .env

```dot
REVERB_HOST=127.0.0.1
REVERB_PORT=8080
REVERB_SCHEME=http

VITE_REVERB_APP_KEY="${REVERB_APP_KEY}"
VITE_REVERB_HOST=localhost
VITE_REVERB_PORT=443
VITE_REVERB_SCHEME=https
```

# nginx

in nginx under ssl

```bash
    location /app {
      proxy_http_version 1.1;
      proxy_set_header Host $http_host;
      proxy_set_header Scheme $scheme;
      proxy_set_header SERVER_PORT $server_port;
      proxy_set_header REMOTE_ADDR $remote_addr;
      proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
      proxy_set_header Upgrade $http_upgrade;
      proxy_set_header Connection "Upgrade";

      proxy_pass http://127.0.0.1:8080;
    }

```

# debug

in echo.js

```js
window.Echo.channel("messages")
    .listen('MesageSent', (event) => {
        console.log(event);
    });
```


# service s6 for workers

```
cd s6-overlay/services.d
mkdir -p reverb/dependencies.d
cd reverb
touch dependencies.d/nginx
touch run
```

in run

```bash
#!/usr/bin/with-contenv sh


cat <<EOL
┌────────────────────┐
       REVERB
└────────────────────┘
EOL


cd /var/www/html
exec s6-setuidgid nginx php artisan reverb:start --debug

```


# LARAVEL

add to `bootstrap/app.php`

```php
channels: __DIR__ . '/../routes/channels.php',
```
