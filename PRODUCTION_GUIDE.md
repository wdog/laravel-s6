# DinnerTable - Production Deployment Guide

## Indice
- [Setup Iniziale](#setup-iniziale)
- [Configurazione Ambiente](#configurazione-ambiente)
- [Switch tra Ambienti](#switch-tra-ambienti)
- [Development (Local)](#development-local)
- [Production](#production)
- [Laravel Reverb Setup](#laravel-reverb-setup)
- [Troubleshooting](#troubleshooting)

---

## Setup Iniziale

### 1. Creazione File `.env`

Il progetto utilizza **file `.env` separati** per development e production:

```bash
# Crea i file di configurazione
cp src/.env.example src/.env.local       # Development (localhost)
cp src/.env.example src/.env.production  # Production (IP/dominio)
```

### 2. Configurazione `.env.local` (Development)

Modifica `src/.env.local`:

```env
APP_NAME=Dinner-Table-Dev
APP_ENV=local
APP_DEBUG=true
APP_HOST=localhost           # Development usa SEMPRE localhost
APP_URL=https://localhost

# Vite HMR - necessario per Hot Module Replacement
VITE_HMR_HOST=localhost

# WebSocket Reverb
VITE_REVERB_HOST=localhost
VITE_REVERB_PORT=443
VITE_REVERB_SCHEME=https

# Mail (Mailpit)
MAIL_HOST=mailpit
MAIL_PORT=1025
```

### 3. Configurazione `.env.production` (Production)

Modifica `src/.env.production`:

```env
APP_NAME=Dinner-Table
APP_ENV=production
APP_DEBUG=false
APP_HOST=192.168.88.40       # Il tuo IP o dominio
APP_URL=https://192.168.88.40

# VITE_HMR_HOST non necessario in production (lascia commentato)

# WebSocket Reverb - DEVE matchare APP_HOST
VITE_REVERB_HOST=192.168.88.40
VITE_REVERB_PORT=443
VITE_REVERB_SCHEME=https

# Mail (SMTP reale)
MAIL_MAILER=smtp
MAIL_HOST=smtp.yourdomain.com
MAIL_PORT=587
MAIL_USERNAME=your_smtp_user
MAIL_PASSWORD=your_smtp_pass
MAIL_ENCRYPTION=tls
```

### 4. Configurazione `vite.config.js`

**IMPORTANTE**: Il file `vite.config.js` è già configurato per caricare `VITE_HMR_HOST` dal file `.env`:

```javascript
import { defineConfig, loadEnv } from 'vite';
import tailwindcss from '@tailwindcss/vite';
import laravel, { refreshPaths } from 'laravel-vite-plugin'

export default defineConfig(({ mode }) => {
    // Carica .env per ottenere VITE_HMR_HOST
    const env = loadEnv(mode, process.cwd(), '');
    const hmrHost = env.VITE_HMR_HOST || 'localhost';

    return {
        plugins: [
            laravel({
                input: ['resources/css/app.css', 'resources/js/app.js', 'resources/css/filament/dinner/theme.css'],
                refresh: [...refreshPaths,
                    "app/Livewire/**",
                    "app/Filament/**",
                    "app/Providers/Filament/**",
                    "resources/views/**"
                ],
                valetTls: false,
                detectTls: false,
            }),
            tailwindcss(),
        ],
        server: {
            host: "0.0.0.0",
            port: 5173,
            strictPort: true,
            hmr: {
                protocol: 'ws',        // Usa 'ws' (non 'wss') per development
                clientPort: 5173,
                host: hmrHost,         // Caricato da VITE_HMR_HOST
            },
            watch: {
                usePolling: true,
            }
        },
    };
});
```

**Note importanti:**
- `loadEnv()` carica automaticamente `VITE_HMR_HOST` dal file `.env`
- `protocol: 'ws'` è necessario perché Vite dev server usa HTTP (non HTTPS)
- `valetTls: false` e `detectTls: false` prevengono l'uso di HTTPS nel file `public/hot`

---

## Switch tra Ambienti

### Script `switch-env.sh`

Usa lo script per passare automaticamente tra development e production:

```bash
# Passare a LOCAL/DEVELOPMENT
./switch-env.sh local

# Passare a PRODUCTION
./switch-env.sh production
```

**Lo script automaticamente:**
- Copia il file `.env.local` o `.env.production` in `src/.env`
- Aggiorna `APP_ENV` nel file `.env` root
- Ferma e rimuove container (incluso mailpit se necessario)
- Build asset in production
- Cache Laravel in production
- Riavvia container con il profilo corretto
- Verifica che tutto funzioni

---

## Configurazione Ambiente

### Variabili `.env` critiche per ambiente

| Variabile | Development (local) | Production |
|-----------|---------------------|------------|
| `APP_ENV` | `local` | `production` |
| `APP_DEBUG` | `true` | `false` |
| `APP_HOST` | `localhost` | `192.168.88.40` o `yourdomain.com` |
| `APP_URL` | `https://localhost` | `https://192.168.88.40` |
| `VITE_HMR_HOST` | `localhost` | Non necessario (lascia vuoto) |
| `VITE_REVERB_HOST` | `localhost` | `192.168.88.40` o `yourdomain.com` |
| `MAIL_HOST` | `mailpit` | `smtp.yourdomain.com` |

**NOTA**: Docker Compose usa `APP_ENV` dal file `.env` root come profilo:
- `APP_ENV=local` → mailpit attivo, Vite HMR attivo
- `APP_ENV=production` → mailpit disabilitato, asset compilati

---

## Development (Local)

### Avvio ambiente development

**Metodo consigliato - Usa lo script:**
```bash
./switch-env.sh local
```

**Metodo manuale:**
```bash
# 1. Copia configurazione local
cp src/.env.local src/.env

# 2. Aggiorna .env root
sed -i 's/^APP_ENV=.*/APP_ENV=local/' .env

# 3. Avvia container con profilo local
docker-compose down
COMPOSE_PROFILES=local docker-compose up -d

# Verifica che i servizi siano attivi
docker-compose ps
# Devi vedere: app, db, mailpit
```

### Installazione dipendenze (prima volta)

```bash
# Composer
docker-compose exec --user $(id -u):$(id -g) app composer install

# NPM
docker-compose exec --user $(id -u):$(id -g) app npm install

# Laravel setup
docker-compose exec --user $(id -u):$(id -g) app php artisan key:generate
docker-compose exec --user $(id -u):$(id -g) app php artisan migrate --seed
```

### Accesso all'applicazione

- **App principale**: `https://localhost`
- **Admin panel**: `https://localhost/admin`
- **User panel**: `https://localhost/dinner`
- **Mailpit UI**: `http://localhost:8025`
- **Vite Dev Server**: `http://localhost:5173` (gestito automaticamente)

### Come funziona in Dev

**Servizi s6-overlay attivi**:
- ✅ **nginx** - Web server HTTPS su porta 443
- ✅ **php-fpm** - PHP FastCGI Process Manager
- ✅ **vite** - Dev server con HMR (solo se `APP_ENV=local`)
- ✅ **queue-worker** - Laravel queue (5 worker paralleli)
- ✅ **reverb** - WebSocket server
- ✅ **schedule** - Laravel scheduler

**Docker Compose servizi**:
- ✅ **app** - Container principale
- ✅ **db** - MySQL 8.4
- ✅ **mailpit** - Mail catcher (solo con `COMPOSE_PROFILES=dev`)

### Hot Module Replacement (HMR)

Il servizio Vite è automaticamente gestito da s6-overlay:
- Parte automaticamente se `APP_ENV=local`
- Ricarica automaticamente CSS/JS quando modifichi i file
- WebSocket su porta 5173
- Configurato per accettare connessioni da qualsiasi IP (0.0.0.0)

**Non serve** fare `npm run dev` manualmente! Il container lo fa già.

Se modifichi file frontend e non vedi cambiamenti:
```bash
# Riavvia il servizio vite
docker-compose restart app
```

### **Note importanti per Development**

**Development usa SEMPRE `localhost`:**
- `APP_URL=https://localhost`
- `VITE_HMR_HOST=localhost`
- `VITE_REVERB_HOST=localhost`

**Se hai bisogno di testare da altri dispositivi nella rete locale:**
- Usa invece l'ambiente **production** con IP `192.168.88.40`
- Oppure crea un file `.env.local-ip` personalizzato

**File `public/hot`:**
- Generato automaticamente da Vite quando parte
- Contiene l'URL del dev server (es. `http://localhost:5173`)
- Se Vite non funziona, riavvia il container: `docker-compose restart app`

### Logs utili

```bash
# Tutti i log del container (s6, nginx, php, vite, queue, etc.)
docker-compose logs -f app

# Solo log Laravel
docker-compose exec app tail -f storage/logs/laravel.log

# Verifica che Vite sia attivo
docker-compose exec app ps aux | grep vite
```

---

## Production

### Deploy Production

**Metodo consigliato - Usa lo script:**
```bash
./switch-env.sh production
```

Lo script automaticamente:
- Copia `src/.env.production` in `src/.env`
- Aggiorna `.env` root con `APP_ENV=production`
- Rimuove `public/hot`
- Build asset (`npm run build`)
- Cache Laravel (config, route, view, filament)
- Riavvia container con profilo production
- Rimuove mailpit se presente
- Verifica che asset siano compilati

**Metodo manuale:**
```bash
# 1. Copia configurazione production
cp src/.env.production src/.env

# 2. Aggiorna .env root
sed -i 's/^APP_ENV=.*/APP_ENV=production/' .env

# 3. Ferma container
docker-compose down
docker rm -f mailpit 2>/dev/null || true

# 4. Avvia temporaneamente per build
docker-compose up -d
sleep 3

# 5. Rimuovi file hot e build asset
docker-compose exec app rm -f public/hot
docker-compose exec app npm run build

# 6. Cache Laravel
docker-compose exec app php artisan config:cache
docker-compose exec app php artisan route:cache
docker-compose exec app php artisan view:cache
docker-compose exec app php artisan filament:optimize

# 7. Riavvia con profilo production
docker-compose down
# up
COMPOSE_PROFILES=production docker-compose up -d --force-recreate
# down in case you need
COMPOSE_PROFILES=production docker-compose down
```

### Cosa cambia in Production

**Servizi s6-overlay attivi**:
- ✅ **nginx** - Web server HTTPS
- ✅ **php-fpm** - PHP FastCGI
- ❌ **vite** - NON parte (check: `if [ "$APP_ENV" = "local" ]`)
- ✅ **queue-worker** - Laravel queue
- ✅ **reverb** - WebSocket server
- ✅ **schedule** - Laravel scheduler

**Docker Compose**:
- ✅ **app** - Container principale
- ✅ **db** - MySQL 8.4
- ❌ **mailpit** - NON parte (profilo `dev` disabilitato)

**Asset**:
- Vite serve file **pre-compilati** da `public/build/`
- NO Hot Module Replacement
- NO porta 5173 esposta

### SSL/HTTPS in Production

Il Dockerfile genera già un certificato self-signed:
```dockerfile
RUN openssl req -x509 -nodes -days 365 \
    -subj  "/C=IT/ST=QC/O=Dark Empire/CN=localhost" \
    -newkey rsa:2048 -keyout /etc/ssl/private/nginx.key \
    -out /etc/ssl/certs/nginx.crt;
```

**Per production usa certificati veri**:

1. **Opzione A - Let's Encrypt (consigliato)**:
   - Usa Certbot per generare certificati
   - Monta i certificati nel container:
   ```yaml
   # docker-compose.yml
   services:
     app:
       volumes:
         - /etc/letsencrypt:/etc/letsencrypt:ro
   ```

2. **Opzione B - Reverse Proxy (Traefik/Nginx Proxy Manager)**:
   - Metti un reverse proxy davanti al container
   - Il proxy gestisce SSL/TLS automaticamente

### Cron Job (Scheduled Tasks)

Il container ha già il servizio `schedule` attivo via s6-overlay.

**NON serve** aggiungere crontab manualmente! Il comando `php artisan schedule:work` è sempre attivo.

Scheduled job configurato:
- **CompleteExpiredAvailabilities**: Daily alle 02:00 AM (Europe/Rome)
  - Completa disponibilità con data passata
  - Cancella prenotazioni non confermate

Verifica che funzioni:
```bash
# Controlla log schedule
docker-compose exec app php artisan schedule:list

# Test manuale
docker-compose exec app php artisan availabilities:complete-expired
```

### Database Backup

```bash
# Backup manuale
docker-compose exec db mysqldump -u laravel -p laravel > backup_$(date +%Y%m%d).sql

# Restore
docker-compose exec -T db mysql -u laravel -p laravel < backup_20250101.sql
```

### Monitoring

```bash
# Container status
docker-compose ps

# Resource usage
docker stats app

# Verifica servizi attivi (nginx, php-fpm, queue, reverb, schedule, vite)
docker-compose exec app ps aux | grep -E "(nginx|php-fpm|queue|reverb|schedule|vite)" | grep -v grep

# Verifica s6 services directory
docker-compose exec app ls -la /etc/services.d/

# Nginx logs
docker-compose exec app tail -f /var/log/nginx/access.log
docker-compose exec app tail -f /var/log/nginx/error.log

# Laravel logs
docker-compose exec app tail -f storage/logs/laravel.log

# Docker compose logs (tutti i servizi s6)
docker-compose logs -f app
```

---

## Laravel Reverb Setup

Laravel Reverb è il server WebSocket ufficiale di Laravel per broadcasting real-time. Questo progetto integra Reverb per funzionalità come notifiche in tempo reale e aggiornamenti live del calendario.

### Cos'è Laravel Reverb?

**Reverb** è un server WebSocket nativo per Laravel che sostituisce servizi esterni come Pusher o Socket.io. Permette di implementare funzionalità real-time senza dipendenze esterne.

**Vantaggi:**
- ✅ Nessun servizio esterno necessario
- ✅ Configurazione semplice
- ✅ Performance elevate
- ✅ Integrato con Laravel Broadcasting

### Installazione e Configurazione

#### 1. Installazione (già fatto in `install.sh`)

```bash
# Installa Reverb
docker-compose exec app composer require laravel/reverb

# Pubblica configurazione
docker-compose exec app php artisan reverb:install

# Aggiorna .env con chiavi Reverb
docker-compose exec app php artisan reverb:install --update-env
```

#### 2. Configurazione `.env`

**Reverb Server (interno al container):**
```env
REVERB_APP_ID=your-app-id
REVERB_APP_KEY=your-app-key
REVERB_APP_SECRET=your-app-secret
REVERB_HOST=127.0.0.1        # Interno al container
REVERB_PORT=8080             # Porta interna
REVERB_SCHEME=http           # HTTP internamente
```

**Reverb Client (frontend JavaScript):**

**Development (localhost):**
```env
VITE_REVERB_APP_KEY="${REVERB_APP_KEY}"
VITE_REVERB_HOST=localhost
VITE_REVERB_PORT=443
VITE_REVERB_SCHEME=https
```

**Production (dominio/IP):**
```env
VITE_REVERB_APP_KEY="${REVERB_APP_KEY}"
VITE_REVERB_HOST=192.168.88.40    # o yourdomain.com
VITE_REVERB_PORT=443
VITE_REVERB_SCHEME=https
```

**IMPORTANTE:**
- `REVERB_HOST=127.0.0.1` è per il server interno
- `VITE_REVERB_HOST` deve matchare il dominio che l'utente usa nel browser
- Porta 443 perché nginx fa da proxy HTTPS

#### 3. Configurazione Nginx (Proxy WebSocket)

Il file nginx include il proxy per `/app` che inoltra a Reverb:

```nginx
# /etc/nginx/conf.d/default.conf
server {
    listen 443 ssl http2;
    server_name _;

    # Reverb WebSocket proxy
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
}
```

**Path:** `/app` è il path standard di Reverb per WebSocket.

#### 4. Servizio S6-Overlay per Reverb

Reverb gira come servizio gestito da s6-overlay all'interno del container.

**Crea la struttura directory:**
```bash
cd s6-overlay/services.d
mkdir -p reverb/dependencies.d
cd reverb
touch dependencies.d/nginx    # Reverb parte dopo nginx
touch run
chmod +x run
```

**File `s6-overlay/services.d/reverb/run`:**
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

#### 5. Broadcasting Configuration

**Abilita channels in `bootstrap/app.php`:**
```php
<?php

use Illuminate\Foundation\Application;

return Application::configure(basePath: dirname(__DIR__))
    ->withRouting(
        web: __DIR__.'/../routes/web.php',
        api: __DIR__.'/../routes/api.php',
        commands: __DIR__.'/../routes/console.php',
        channels: __DIR__.'/../routes/channels.php',  // Aggiungi questa riga
        health: '/up',
    )
    // ...
```

**File `routes/channels.php` (esempio):**
```php
<?php

use Illuminate\Support\Facades\Broadcast;

Broadcast::channel('App.Models.User.{id}', function ($user, $id) {
    return (int) $user->id === (int) $id;
});
```

#### 6. Test WebSocket

**JavaScript debug (in `resources/js/echo.js`):**
```javascript
// Ascolta un canale di test
window.Echo.channel("messages")
    .listen('MessageSent', (event) => {
        console.log('Messaggio ricevuto:', event);
    });
```

### Verifica Funzionamento

**1. Verifica che Reverb sia attivo:**
```bash
# Controlla processo reverb
docker-compose exec app ps aux | grep reverb

# Deve mostrare: php artisan reverb:start --debug
```

**2. Test connessione WebSocket:**
```bash
# Log Reverb in tempo reale
docker-compose logs -f app | grep REVERB

# Apri browser console (F12) e controlla:
# WebSocket connection to 'wss://localhost/app/...' opened
```

### Architettura Reverb

**Flow del WebSocket:**
```
Browser (wss://localhost/app)
    ↓ HTTPS/WSS
Nginx (443) - proxy WebSocket
    ↓ HTTP
Reverb Server (127.0.0.1:8080)
    ↓
Laravel App (broadcasting events)
```

**Flow di un evento:**
1. Laravel triggera `broadcast(new MyEvent())`
2. Reverb riceve l'evento
3. Reverb invia via WebSocket ai client connessi
4. Laravel Echo (frontend) riceve e processa

### Differenze Local vs Production

**Local:**
```env
VITE_REVERB_HOST=localhost
VITE_REVERB_SCHEME=https
```
- Client connette a `wss://localhost/app`
- Nginx proxy a `http://127.0.0.1:8080`

**Production:**
```env
VITE_REVERB_HOST=192.168.88.40  # o yourdomain.com
VITE_REVERB_SCHEME=https
```
- Client connette a `wss://192.168.88.40/app`
- Nginx proxy a `http://127.0.0.1:8080`

**IMPORTANTE:** `VITE_REVERB_HOST` deve sempre matchare il dominio/IP usato dall'utente finale.

---

## Troubleshooting

### Vite HMR non funziona

**Sintomi**: Asset non si ricaricano, console browser mostra errori WebSocket o errori di connessione a `localhost:5173`.

**Soluzione**:
1. Verifica di essere in ambiente LOCAL:
   ```bash
   cat .env | grep APP_ENV
   # Deve essere: APP_ENV=local
   ```

2. Verifica che `VITE_HMR_HOST` sia configurato correttamente in `src/.env`:
   ```env
   VITE_HMR_HOST=localhost
   ```

3. Verifica il file `public/hot`:
   ```bash
   docker-compose exec app cat public/hot
   # Deve essere: http://localhost:5173
   ```

4. Se il file hot è errato, riavvia il container:
   ```bash
   docker-compose exec app rm -f public/hot
   docker-compose restart app
   sleep 5
   docker-compose exec app cat public/hot
   ```

5. Verifica che Vite sia attivo:
   ```bash
   docker-compose exec app ps aux | grep "node.*vite"
   # Dovresti vedere un processo node che esegue vite
   ```

### Reverb WebSocket non connette

**Sintomi**: Funzionalità real-time non funzionano.

**Soluzione**:
1. Verifica configurazione Reverb in `.env`:
   ```env
   VITE_REVERB_HOST=192.168.88.40  # o il tuo IP
   VITE_REVERB_PORT=443
   VITE_REVERB_SCHEME=https
   ```

2. Controlla che Reverb sia attivo:
   ```bash
   docker-compose exec app ps aux | grep reverb
   ```

3. Verifica proxy Nginx per `/app`:
   ```bash
   docker-compose exec app cat /etc/nginx/conf.d/default.conf | grep -A 10 "location /app"
   ```

### Asset non si caricano in Production

**Sintomi**: CSS/JS mancanti, pagina senza stile, oppure cerca ancora `localhost:5173`.

**Causa comune**: File `public/hot` presente (indica a Laravel di usare Vite dev server).

**Soluzione**:
1. **Rimuovi il file hot** (CRITICO):
   ```bash
   docker-compose exec app rm -f public/hot
   ```

2. Verifica che asset siano compilati:
   ```bash
   docker-compose exec app ls -la public/build/
   # Devi vedere: manifest.json e cartella assets/
   ```

3. Se mancano, compila:
   ```bash
   docker-compose exec app npm run build
   ```

4. Pulisci cache views:
   ```bash
   docker-compose exec app php artisan view:clear
   docker-compose exec app php artisan optimize:clear
   docker-compose exec app php artisan filament:optimize-clear
   ```

5. Verifica che ora usi i file compilati:
   ```bash
   docker-compose exec app curl -k -s https://localhost | grep -o 'build/assets/[^"]*' | head -5
   # Deve mostrare: build/assets/app-XXXX.js, build/assets/app-XXXX.css, etc.
   ```

### Mailpit non si vede in Dev

**Sintomi**: Mailpit UI non accessibile su porta 8025.

**Soluzione**:
1. Verifica `APP_ENV` in `.env` root:
   ```bash
   grep APP_ENV .env
   # Deve essere: APP_ENV=local
   ```

2. Riavvia con profilo corretto:
   ```bash
   docker-compose down
   export $(grep APP_ENV= .env | xargs) && COMPOSE_PROFILES=$APP_ENV docker-compose up -d

   # Verifica che mailpit sia partito
   docker-compose ps | grep mailpit
   ```

### Queue non processa job

**Sintomi**: Job rimangono in coda, nessuna elaborazione.

**Soluzione**:
1. Verifica che queue worker sia attivo:
   ```bash
   docker-compose exec app ps aux | grep "queue:work"
   # Dovresti vedere 5 processi
   ```

2. Controlla log queue:
   ```bash
   docker-compose logs app | grep "LARAVEL QUEUE"
   ```

3. Flush e riavvia queue:
   ```bash
   docker-compose exec app php artisan queue:flush
   docker-compose restart app
   ```

### Permessi file (403 Forbidden)

**Sintomi**: Errori 403, "Permission denied" nei log.

**Soluzione**:
1. Verifica ownership:
   ```bash
   docker-compose exec app ls -la /var/www/html
   ```

2. Sistema permessi (dentro container):
   ```bash
   docker-compose exec app chown -R nginx:www-data /var/www/html
   docker-compose exec app chmod -R 755 /var/www/html/storage
   docker-compose exec app chmod -R 755 /var/www/html/bootstrap/cache
   ```

3. Verifica che PUID/PGID siano corretti in `.env` root:
   ```env
   PUID=1000  # $(id -u)
   PGID=1000  # $(id -g)
   ```

### Container non si avvia

**Sintomi**: Container esce immediatamente dopo start.

**Soluzione**:
1. Controlla log completi:
   ```bash
   docker-compose logs app
   ```

2. Verifica sintassi `.env`:
   ```bash
   docker-compose config
   ```

3. Controlla s6-overlay init:
   ```bash
   docker-compose up app  # senza -d per vedere output
   ```

---

## Checklist Pre-Deploy Production

- [ ] `.env` configurato con `APP_ENV=production` e `APP_DEBUG=false`
- [ ] Database credentials sicure e backup funzionante
- [ ] SMTP mail server configurato (no Mailpit)
- [ ] SSL/TLS certificati validi (Let's Encrypt o altro)
- [ ] **File `public/hot` RIMOSSO** (critico!)
- [ ] `npm run build` eseguito e `public/build/` popolato
- [ ] Cache Laravel ottimizzate (config, route, view, filament)
- [ ] Scheduled tasks verificati (schedule:list)
- [ ] Queue workers attivi (5 processi)
- [ ] **`VITE_REVERB_HOST` configurato con dominio reale** (non localhost!)
- [ ] Reverb WebSocket funzionante
- [ ] Monitoring e log attivi
- [ ] Database backup automatico configurato
- [ ] `APP_ENV=production` impostato (mailpit auto-disabilitato)

### Note sulla configurazione attuale

**VITE_REVERB_HOST nel tuo `.env`:**
- Attualmente impostato su `192.168.88.40`
- ⚠️ Se stai deployando in production su un dominio pubblico (es. `dinnertable.com`), DEVI cambiarlo:
  ```env
  VITE_REVERB_HOST=dinnertable.com  # Il tuo dominio reale
  ```
- Il valore deve corrispondere al dominio/IP che l'utente finale userà nel browser
- Se lasci `192.168.88.40` in production, WebSocket non funzionerà per utenti esterni alla tua rete locale

---

## Comandi Utili Recap

### Development
```bash
# Avvio completo dev (con mailpit)
export $(grep APP_ENV= .env | xargs) && COMPOSE_PROFILES=$APP_ENV docker-compose up -d

# Restart Vite HMR
docker-compose restart app

# Watch logs
docker-compose logs -f app
```

### Production
```bash
# Rimuovi file hot prima di tutto
docker-compose exec app rm -f public/hot

# Build asset
docker-compose exec app npm run build

# Cache ottimizzazioni
docker-compose exec app php artisan config:cache
docker-compose exec app php artisan route:cache
docker-compose exec app php artisan view:cache
docker-compose exec app php artisan filament:optimize

# Deploy (usa APP_ENV come profile)
docker-compose down
export $(grep APP_ENV= .env | xargs) && COMPOSE_PROFILES=$APP_ENV docker-compose up -d --force-recreate

# Verifica che usi asset compilati
docker-compose exec app curl -k -s https://localhost | grep -o 'build/assets' | head -1
```

### Manutenzione
```bash
# Backup DB
docker-compose exec db mysqldump -u laravel -plaravel laravel > backup.sql

# Clear cache
docker-compose exec app php artisan optimize:clear

# Restart queue
docker-compose exec app php artisan queue:restart

# Check services
docker-compose exec app s6-svstat /var/run/s6/services/*
```

---

**Buon deploy! 🚀**
