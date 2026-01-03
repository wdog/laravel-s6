# DinnerTable - Laravel Application

Applicazione web per la gestione e coordinamento di cene di gruppo, basata su Laravel 12 + Filament v4 con supporto WebSocket real-time tramite Laravel Reverb.

## Quick Start

### Configurazione Iniziale

1. **Crea i file di ambiente:**
```bash
cp src/.env.example src/.env.local
cp src/.env.example src/.env.production
```

2. **Configura `src/.env.local` per development** (vedi [PRODUCTION_GUIDE.md](PRODUCTION_GUIDE.md))

3. **Avvia l'ambiente:**
```bash
# Development (localhost con HMR e Mailpit)
./switch-env.sh local

# Production (IP o dominio pubblico)
./switch-env.sh production
```

**Per guida completa:** Leggi [PRODUCTION_GUIDE.md](PRODUCTION_GUIDE.md)

---

## Ambienti: Local vs Production

### Local Development Mode (`./switch-env.sh local`)

**Caratteristiche:**
- ✅ **Vite HMR** - Hot Module Replacement per CSS/JS
- ✅ **Mailpit** - Mail catcher su http://localhost:8025
- ✅ **Debug mode** - Errori dettagliati
- ✅ **Laravel Reverb** - WebSocket server su wss://localhost/app
- ✅ **File watcher** - Ricarica automatica modifiche

**Servizi Docker attivi:**
- `app` - Container principale (nginx, php-fpm, vite, reverb, queue, schedule)
- `db` - MySQL 8.4.3
- `mailpit` - Mail catcher (profilo `local`)

**Porte esposte:**
- `443` - HTTPS (app)
- `5173` - Vite HMR
- `8025` - Mailpit UI
- `3306` - MySQL

**Accesso:**
- App: https://localhost
- Admin Panel: https://localhost/admin
- User Panel: https://localhost/dinner
- Mailpit: http://localhost:8025

### Production Mode (`./switch-env.sh production`)

**Caratteristiche:**
- ✅ **Asset compilati** - Build pre-compilato in `public/build/`
- ✅ **Laravel cache** - Config, route, view ottimizzate
- ✅ **Laravel Reverb** - WebSocket production-ready
- ✅ **Queue workers** - 5 worker paralleli
- ✅ **Scheduler** - Cron jobs Laravel
- ❌ **NO Vite HMR** - Usati solo asset compilati
- ❌ **NO Mailpit** - Usa SMTP reale
- ❌ **NO Debug** - Errori nascosti

**Servizi Docker attivi:**
- `app` - Container principale (nginx, php-fpm, reverb, queue, schedule)
- `db` - MySQL 8.4.3

**Porte esposte:**
- `443` - HTTPS (app)
- `3306` - MySQL

**Accesso:**
- App: https://192.168.88.40 (o il tuo dominio)
- Admin Panel: https://192.168.88.40/admin
- User Panel: https://192.168.88.40/dinner

---

## Tecnologie e Servizi

### Stack Applicativo

- **PHP 8.4** - Backend
- **Laravel 12** - Framework principale
- **Filament v4** - Admin/App panels
- **MySQL 8.4.3** - Database
- **Vite 7.3** - Frontend bundler
- **Tailwind CSS v4** - Styling
- **Alpine.js** - JavaScript reattivo
- **Livewire v3** - Components full-stack

### Servizi S6-Overlay

Tutti i servizi sono gestiti da **s6-overlay** all'interno del container `app`:

1. **nginx** - Web server HTTPS (porta 443)
2. **php-fpm** - FastCGI Process Manager
3. **vite** - Dev server HMR (solo in `local`, porta 5173)
4. **reverb** - WebSocket server (porta 8080 interna, proxy su `/app`)
5. **queue-worker** - Laravel queue (5 worker paralleli)
6. **schedule** - Laravel scheduler (cron jobs)

**Come verificare i servizi:**
```bash
docker-compose exec app ps aux | grep -E "(nginx|php-fpm|vite|reverb|queue|schedule)"
```

### Laravel Reverb - WebSocket Real-Time

**Reverb** è il server WebSocket ufficiale di Laravel per broadcasting real-time.

**Configurazione:**
- Server interno: `127.0.0.1:8080`
- Proxy Nginx: `wss://your-domain/app`
- Client JS: connessione automatica via Laravel Echo

**Funzionalità real-time attive:**
- Aggiornamento disponibilità cene
- Notifiche prenotazioni
- Updates calendario gruppo

**Setup dettagliato:** Vedi sezione "Laravel Reverb Setup" in [PRODUCTION_GUIDE.md](PRODUCTION_GUIDE.md)

---

## Switch tra Ambienti

Lo script `switch-env.sh` gestisce automaticamente:

1. ✅ Copia file `.env.local` o `.env.production` → `src/.env`
2. ✅ Aggiorna `APP_ENV` in `.env` root
3. ✅ Stop/rimozione container (incluso mailpit se necessario)
4. ✅ Build asset (solo production)
5. ✅ Cache Laravel (solo production)
6. ✅ Restart container con profilo corretto (`local` o `production`)
7. ✅ Verifica servizi attivi

**Esempio:**
```bash
# Passa a local
./switch-env.sh local
# Output: app, db, mailpit attivi + Vite HMR

# Passa a production
./switch-env.sh production
# Output: app, db attivi + asset compilati
```

---

## Mailpit - Mail Catcher (Solo Local)

**Mailpit** è attivo **SOLO in ambiente local** (profilo Docker Compose `local`).

**Caratteristiche:**
- Intercetta tutte le email inviate dall'app
- UI web su http://localhost:8025
- API REST su http://localhost:8025/api
- SMTP su porta 1025

**In production:**
- Mailpit è disabilitato (profilo non caricato)
- Usa SMTP reale configurato in `src/.env.production`

**Configurazione `.env.local`:**
```env
MAIL_MAILER=smtp
MAIL_HOST=mailpit
MAIL_PORT=1025
MAIL_USERNAME=null
MAIL_PASSWORD=null
MAIL_ENCRYPTION=null
```

**Verifica stato:**
```bash
# Local: deve essere presente
docker ps | grep mailpit

# Production: NON deve essere presente
docker ps | grep mailpit
# Output: (vuoto)
```

---

# Laravel S6 Docker (Base Template)

This repository provides a fully automated environment for installing and running a Laravel application from scratch using Docker, Docker Compose, and the S6 process supervisor.

## What I've Done

- **Containerized Laravel Setup:**
  Built a Docker-based workflow to install and run Laravel without manual server configuration. All dependencies and services are defined in Dockerfiles and Compose files.

- **Service Supervision with S6:**
  Integrated the S6 process supervisor to manage multiple services within containers, ensuring reliable startup, shutdown, and process management.

- **Automated Installation Scripts:**
  Wrote shell scripts to automate the installation of Laravel and its required components, making project setup fast and reproducible.

- **Multi-Service Orchestration:**
  Used Docker Compose to orchestrate containers for the app, database, and other supporting services.

- **Environment Configuration:**
  Enabled easy switching between development and production environments by managing environment variables and Docker Compose profiles.

- **Documentation & Usage Instructions:**
  Provided clear instructions for cloning the repository, building containers, installing Laravel, and running the application—all with minimal prerequisites (just Docker and Docker Compose).

---

## install.sh — Detailed Documentation

The `install.sh` script automates the Laravel setup process inside Docker containers, leveraging S6 for process supervision. Here’s a detailed breakdown of its workflow and features:

### 1. Preparation

- **Clean Workspace:**
  Removes previous Laravel source directories and creates a fresh `src` directory for your new app.
- **Application Naming:**
  Prompts you to enter your desired application name, used for environment and configuration.

### 2. Laravel Installation

- **Composer Create Project:**
  Uses Composer (via Docker container) to create a new Laravel app in the `src` directory.
- **Git Initialization:**
  Initializes a new local Git repository for version control.

### 3. Environment Setup

- **Copy & Edit `.env`:**
  Copies `.env.example` to `.env` and customizes key variables (app name, locale, database, and URLs) using automated script edits.
- **App Key Generation:**
  Runs `php artisan key:generate` to securely set the Laravel encryption key.

### 4. Filament Admin Panel Integration

- **Filament Installation:**
  Installs Filament and Filament Shield via Composer for admin panel and permission management.
- **Config & Translation Publishing:**
  Publishes Filament Shield config and translations for custom admin experience.
- **Panel Setup:**
  Runs Filament setup commands to enable panels and user management.

### 5. Database Initialization

- **Migration & Seeding:**
  Runs initial migrations to set up database tables, then seeds the database with a default admin user (e.g., `admin@example.com` with password `password`).

### 6. Frontend & Assets

- **Node & Vite:**
  Installs Node.js dependencies and writes a default `vite.config.js` for asset building (Vite + Tailwind CSS).
- **Asset Compilation:**
  Prepares assets for development and production use.

### 7. Filament Customization

- **User Model & Routing:**
  Updates user model and routes for Filament compatibility.
- **Panel Appearance:**
  Customizes admin panel look and feel.

### 8. Permission & Policy Management

- **Shield Setup:**
  Configures Filament Shield, creates super-admin, and generates resource policies for granular access control.

### 9. Code Quality

- **Tighten Duster:**
  Installs and runs Duster for automatic code quality and style checks.

### 10. Broadcasting Integration

- **Reverb Installation:**
  Installs broadcasting with Reverb and updates environment variables for event broadcasting.

### 11. Docker Compose Orchestration

- **Container Restart:**
  Stops all running containers, starts them with Docker Compose, and ensures the app is running inside a managed environment.
- **Git Commit:**
  Commits all changes to the local repository as a snapshot of your initialized environment.

---

## Usage

To run the installation script, from your project directory execute:

```sh
bash install.sh
```

Follow on-screen prompts, and let the script handle the rest—your Laravel app will be installed, configured, and ready to run inside Docker.

---

## Project Structure

- `Dockerfile` — Defines the PHP/Laravel container.
- `docker-compose.yml` — Orchestrates the application and supporting services.
- `install.sh` — Automates the entire setup and installation process.

## License

MIT

---

**Laravel S6 Docker** — Fast, reproducible Laravel development with Docker and S6!
