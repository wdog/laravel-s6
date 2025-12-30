#!/bin/bash

set -e

# Colori per output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Funzione per stampare errori
error() {
    echo -e "${RED}✗ Error: $1${NC}"
    exit 1
}

# Funzione per stampare successo
success() {
    echo -e "${GREEN}✓ $1${NC}"
}

# Funzione per stampare info
info() {
    echo -e "${BLUE}[INFO] $1${NC}"
}

# Funzione per stampare warning
warning() {
    echo -e "${YELLOW}⚠ $1${NC}"
}

# Check parametro
if [ $# -eq 0 ]; then
    error "Usage: ./switch-env.sh [local|production]"
fi

ENV=$1

# Valida parametro
if [ "$ENV" != "local" ] && [ "$ENV" != "production" ]; then
    error "Invalid environment. Use 'local' or 'production'"
fi

# Converti in maiuscolo per display
ENV_UPPER=$(echo "$ENV" | tr '[:lower:]' '[:upper:]')

echo "=========================================="
echo "  Switching to $ENV_UPPER Environment"
echo "=========================================="
echo ""

# Step 1: Copy environment file
info "[1/9] Copying src/.env.$ENV to src/.env..."
if [ ! -f "src/.env.$ENV" ]; then
    error "File src/.env.$ENV not found!"
fi
cp "src/.env.$ENV" src/.env
success ".env updated for $ENV_UPPER environment"
echo ""

# Step 2: Update root .env
info "[2/9] Updating root .env to APP_ENV=$ENV..."
sed -i "s/^APP_ENV=.*/APP_ENV=$ENV/" .env
success "Root .env updated"
echo ""

# Step 3: Stop containers
info "[3/9] Stopping Docker containers..."
docker-compose down
# Force remove mailpit if exists (to ensure clean profile switch)
docker rm -f mailpit 2>/dev/null || true
success "Containers stopped"
echo ""

if [ "$ENV" = "production" ]; then
    # PRODUCTION MODE

    # Step 4: Start containers temporarily
    info "[4/9] Starting temporary container for asset build..."
    docker-compose up -d
    sleep 3
    echo ""

    # Step 5: Remove public/hot (CRITICAL!)
    info "[5/9] Removing public/hot file..."
    docker-compose exec app rm -f public/hot
    success "public/hot removed"
    echo ""

    # Step 6: Build production assets
    info "[6/9] Building production assets..."
    docker-compose exec app npm run build
    success "Assets built"
    echo ""

    # Step 7: Cache Laravel optimizations
    info "[7/9] Caching Laravel optimizations..."
    docker-compose exec app php artisan config:cache
    docker-compose exec app php artisan route:cache
    docker-compose exec app php artisan view:cache
    docker-compose exec app php artisan filament:optimize
    success "Caches optimized"
    echo ""

    # Step 8: Restart with production profile
    info "[8/9] Restarting containers with production profile..."
    docker-compose down
    # Force remove mailpit to prevent it from starting in production
    docker rm -f mailpit 2>/dev/null || true
    COMPOSE_PROFILES=production docker-compose up -d --force-recreate
    success "Containers restarted"
    echo ""

    # Step 9: Verify
    info "[9/9] Waiting for services to be ready..."
    sleep 5
    echo ""

    info "Verifying assets are compiled..."
    if docker-compose exec app curl -k -s https://localhost | grep -q "build/assets"; then
        success "Assets are served from build/ (production mode)"
    else
        warning "Assets may not be compiled correctly!"
    fi
    echo ""

    # Verify mailpit is NOT running
    if docker ps --format '{{.Names}}' | grep -q "^mailpit$"; then
        warning "Mailpit is still running in production! Stopping..."
        docker stop mailpit && docker rm mailpit
    fi
    echo ""

    echo "=========================================="
    echo "  PRODUCTION Environment Ready!"
    echo "=========================================="
    echo ""
    docker-compose ps
    echo ""
    echo "Services:"
    echo "  - App (HTTPS):     https://192.168.88.40"
    echo "  - Admin Panel:     https://192.168.88.40/admin"
    echo "  - App Panel:       https://192.168.88.40/dinner"
    echo ""
    echo "Production features:"
    echo "  ✓ Compiled assets (no HMR)"
    echo "  ✓ Laravel caches optimized"
    echo "  ✓ Debug mode OFF"
    echo "  ✓ Mailpit disabled"
    echo ""
    warning "IMPORTANT: Update MAIL_* settings in src/.env.production"
    warning "           for real SMTP in production!"
    echo ""

else
    # LOCAL/DEV MODE

    # Step 4: Remove public/hot if exists
    info "[4/9] Removing public/hot file (if exists)..."
    docker-compose run --rm app rm -f public/hot 2>/dev/null || true
    success "public/hot removed"
    echo ""

    # Step 5: Clear Laravel caches
    info "[5/9] Clearing Laravel caches..."
    docker-compose run --rm app php artisan optimize:clear 2>/dev/null || true
    docker-compose run --rm app php artisan filament:optimize-clear 2>/dev/null || true
    success "Caches cleared"
    echo ""

    # Step 6-8: Placeholders for consistent numbering
    info "[6/9] Skipping asset build (Vite HMR will be used)..."
    info "[7/9] Skipping cache optimization (dev mode)..."
    info "[8/9] Starting containers with local profile..."
    echo ""

    # Start containers with local profile
    COMPOSE_PROFILES=local docker-compose up -d
    success "Containers started"
    echo ""

    # Step 9: Verify
    info "[9/9] Waiting for services to be ready..."
    sleep 5
    echo ""

    echo "=========================================="
    echo "  LOCAL/DEV Environment Ready!"
    echo "=========================================="
    echo ""
    docker-compose ps
    echo ""
    echo "Services:"
    echo "  - App (HTTPS):     https://localhost"
    echo "  - Admin Panel:     https://localhost/admin"
    echo "  - App Panel:       https://localhost/dinner"
    echo "  - Mailpit UI:      http://localhost:8025"
    echo "  - Vite HMR:        http://localhost:5173"
    echo ""
    success "Vite dev server is running with Hot Module Replacement!"
    echo "Changes to CSS/JS will auto-reload in the browser."
    echo ""
fi
