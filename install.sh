#!/usr/bin/bash

composer='docker run --rm -it --user 1000:1000 -v .:/opt -w /opt composer:latest'

# Variabili di configurazione
PROJECT_DIR="src"
DB_NAME="laravel"
DB_USER="laravel"
DB_PASS="laravel"
APP_NAME="MyLaravelApp"


createDir(){

    docker-compose down --remove-orphans

    banner "Clean Existing Directories"
    sudo rm -rf mysql
    rm -rf "$PROJECT_DIR"

    banner "Creazione della directory src"
    mkdir -p "$PROJECT_DIR"
    cd "$PROJECT_DIR" || { echo "Impossibile accedere alla directory $PROJECT_DIR"; exit 1; }

    banner "Installazione di Laravel..."
    $composer create-project --prefer-dist laravel/laravel . --no-scripts --quiet
}

setupProject(){
    # Configurazione del file .env
    banner "Configurazione del file .env..."
    cp .env.example .env

    # Aggiornamento delle variabili di ambiente per il database
    sed -i "s/APP_NAME=Laravel/APP_NAME=$APP_NAME/" .env
    sed -i "s/APP_FAKER_LOCALE=.*/APP_FAKER_LOCALE=it_IT/" .env
    sed -i "s/APP_URL=.*/APP_URK=https:\/\/localhost/" .env
    sed -i "s/APP_LOCALE=.*/APP_LOCALE=it/" .env
    sed -i "s/# DB_HOST=.*/DB_HOST=db/" .env
    sed -i "s/# DB_PORT=.*/DB_PORT=3306/" .env

    sed -i "s/DB_CONNECTION=.*/DB_CONNECTION=mysql/" .env
    sed -i "s/# DB_DATABASE=.*/DB_DATABASE=$DB_NAME/" .env
    sed -i "s/# DB_USERNAME=.*/DB_USERNAME=$DB_USER/" .env
    sed -i "s/# DB_PASSWORD=.*/DB_PASSWORD=$DB_PASS/" .env
}


keyGenerate(){
    $composer php artisan key:generate
    git init
    git add .
    git commit -a -m "inital commit"
}

installFilament(){
    banner "Installazione di Filament..."
    $composer require filament/filament  --ignore-platform-reqs -W --quiet
}

installShield(){
    banner "Installazione di Filament Shield..."
    $composer require bezhansalleh/filament-shield --ignore-platform-reqs -W --quiet
    $composer php artisan vendor:publish --tag=filament-shield
}

createUser(){
# Creazione di un utente di test tramite seeder
banner "Creazione di un utente admin..."
cat <<EOL > database/seeders/UserSeeder.php
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
sed -i "s/class DatabaseSeeder extends Seeder/class DatabaseSeeder extends Seeder\n{\n    public function run()\n    {\n        \$this->call(UserSeeder::class);\n    }\n}/" database/seeders/DatabaseSeeder.php


}


startUp(){

    docker-compose up -d
    docker-composer exec -u 1000:1000 app npm install
    sleep 3
    $composer php artisan migrate --step --seed
}

setupShield(){
    $compose php artisan shield:install
    $compose php artisan shield:setup
}


banner(){
    echo "----- " $1 " -----"
}



#createDir
# setupProject
 keyGenerate
# installFilament
# installShield
# setupShield
# createUser
# startUp

# Esecuzione del seeder
#php artisan db:seed

echo "Installazione completata!"
echo "Accesso all'applicazione: https://localhost"
echo "Utente di test creato:"
echo "Email: admin@example.com"
echo "Password: password"
