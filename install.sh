#!/usr/bin/bash

set -e

#sudo rm -rf ~/.cache/composer
mkdir -p ~/.cache/composer
#chmod 777 ~/.cache/composer -R

composer="docker run --rm -it --user 1000:1000 -v .:/opt -v $HOME/.cache/composer:/tmp/cache -w /opt composer:latest"
run_in_app="docker-compose exec -u 1000:1000 app"

# Variabili di configurazione
PROJECT_DIR="src"
DB_NAME="laravel"
DB_USER="laravel"
DB_PASS="laravel"
APP_NAME="MyLaravelApp"


main(){
    createDir
    setupProject
    keyGenerate
    installFilament
    startUpDocker
    install_npm
    run_migrations
    vite
    setupFilament
    installShield
    createUser
    setupShield
    extraComponents
    banner "Installazione completata!"
    # echo "Accesso all'applicazione: https://localhost"
    # echo "Utente di test creato:"
    # echo "Email: admin@example.com"
    # echo "Password: password"
}



createDir() {
    banner "Clean Existing Directories"
    sudo rm -rf mysql
    rm -rf "$PROJECT_DIR"

    banner "Creazione della directory src"
    mkdir -p "$PROJECT_DIR"
    cd "$PROJECT_DIR" || {
        echo "Impossibile accedere alla directory $PROJECT_DIR"
        exit 1
    }

    banner "Installazione di Laravel..."
    $composer create-project --prefer-dist laravel/laravel . --no-scripts
}

setupProject() {
    # Configurazione del file .env
    banner "Configurazione del file .env..."
    cp .env.example .env

    # Aggiornamento delle variabili di ambiente per il database
    sed -i "s/APP_NAME=Laravel/APP_NAME=$APP_NAME/" .env
    sed -i "s/APP_FAKER_LOCALE=.*/APP_FAKER_LOCALE=it_IT/" .env
    sed -i "s/APP_URL=.*/APP_URL=https:\/\/localhost/" .env
    sed -i "s/APP_LOCALE=.*/APP_LOCALE=it/" .env
    sed -i "s/# DB_HOST=.*/DB_HOST=db/" .env
    sed -i "s/# DB_PORT=.*/DB_PORT=3306/" .env

    sed -i "s/DB_CONNECTION=.*/DB_CONNECTION=mysql/" .env
    sed -i "s/# DB_DATABASE=.*/DB_DATABASE=$DB_NAME/" .env
    sed -i "s/# DB_USERNAME=.*/DB_USERNAME=$DB_USER/" .env
    sed -i "s/# DB_PASSWORD=.*/DB_PASSWORD=$DB_PASS/" .env
}

keyGenerate() {
    $composer php artisan key:generate
    git init
    git add .
    git commit -a -m "inital commit"
}

installFilament() {
    banner "Installazione di Filament..."
    $composer require filament/filament --ignore-platform-reqs -W
}

installShield() {
    banner "Installazione di Filament Shield..."
    $composer require bezhansalleh/filament-shield --ignore-platform-reqs -W
}

createUser() {
    # Creazione di un utente di test tramite seeder
    banner "Creazione di un utente admin..."
    cat <<EOL >database/seeders/UserSeeder.php
<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use App\Models\User;

class UserSeeder extends Seeder
{
    public function run()
    {
        User::create([
            'name' => 'Admin',
            'email' => 'admin@example.com',
            'password' => bcrypt('password'),
        ]);
    }
}
EOL

    # Aggiornamento del file DatabaseSeeder.php
    cat <<EOL >database/seeders/DatabaseSeeder.php
<?php

namespace Database\Seeders;

use App\Models\User;
use Illuminate\Database\Seeder;

class DatabaseSeeder extends Seeder
{
    public function run()
    {
        \$this->call(UserSeeder::class);
    }
}
EOL

    $run_in_app php artisan db:seed
}

startUpDocker() {

    banner "Avvio dell'applicazione..."
    docker-compose down --remove-orphans
    docker-compose up -d
    sleep 5
}


install_npm(){
    banner "Installazione delle dipendenze NODEJS..."
    $run_in_app npm install
}


vite(){

    cat <<EOL >vite.config.js
import { defineConfig } from 'vite';
import tailwindcss from '@tailwindcss/vite';
import laravel, { refreshPaths } from 'laravel-vite-plugin'

export default defineConfig({
    plugins: [
        laravel({
            input: ['resources/css/app.css', 'resources/js/app.js'],
            refresh: [
                ...refreshPaths,
                'app/Filament/**',
            ],
        }),
        tailwindcss(),
    ],
    server: {
        host: "0.0.0.0",
        hmr: {
            host: "localhost",
            https: true
        }
    },
});
EOL

}

setupFilament(){
    $run_in_app php artisan filament:install -F -n --panels

    sed -i "s/->path('admin')/->path('\/')/" app/Providers/Filament/AdminPanelProvider.php
    echo "<?php" > routes/web.php

    cat << EOL > app/Models/User.php
<?php

namespace App\Models;

use Filament\Panel;
use Spatie\Permission\Traits\HasRoles;
use Illuminate\Notifications\Notifiable;
use Filament\Models\Contracts\FilamentUser;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Foundation\Auth\User as Authenticatable;

class User extends Authenticatable implements FilamentUser
{
    use HasFactory, Notifiable, HasRoles;

    public function canAccessPanel(Panel \$panel): bool
    {
        return true;
    }
}

EOL


}

setupShield() {
    banner "setup shield..."
    $run_in_app php artisan vendor:publish --tag=filament-shield-config
    $run_in_app php artisan vendor:publish --tag=filament-shield-translations
    $run_in_app php artisan shield:setup --fresh --minimal
    $run_in_app php artisan shield:install admin -n
    $run_in_app php artisan shield:generate --panel=admin --all --ignore-existing-policies
    $run_in_app php artisan shield:super-admin

}


run_migrations(){
    banner "Esecuzione delle migrations e seeder..."
    $run_in_app php artisan migrate --step
}

banner() {
    echo "--------------------------------------------------------------"
    echo ">>>>>" $1
    echo "--------------------------------------------------------------"
    echo ""
}

extraComponents(){
    $run_in_app composer require tightenco/duster
    $run_in_app ./vendor/bin/duster fix --using pint

    sed -i "s/->login()/->login()->renderHook('panels::body.end', fn (): string => Blade::render(\"\@vite('resources\/js\/app.js')\"))/" app/Providers/Filament/AdminPanelProvider.php
    sed -i "s/Amber/Lime/" app/Providers/Filament/AdminPanelProvider.php

    git add .
    git commit -a -m "starting point"
    git status
}

# RUN
main
