#!/usr/bin/bash


source .env
cd src

if [ ! -d ".git" ]; then
    echo ".git directory does not exist. Initializing Git repository..."
    git init
    echo "Git repository initialized."
else
    echo ".git directory already exists. Skipping Git initialization."
fi

docker-compose down --remove-orphans
docker-compose up -d


de="docker-compose exec -u $PIUD:$PGID app "

$de npm install


$de php artisan opt:cl
$de php artisan key:generate
$de php artisan vendor:publish --tag=filament-shield
$de php artisan migrate
$de php artisan db:seed

#de php artisan shield:install
#de php artisan shield:setup



