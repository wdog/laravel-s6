# Laravel S6 Docker

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
