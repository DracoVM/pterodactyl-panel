#!/bin/bash

# Replace these placeholders with your actual values
NGROK_AUTH_TOKEN="YOUR_NGROK_AUTH_TOKEN"
DATABASE_HOST="localhost"
DATABASE_NAME="pterodactyl"
DATABASE_USER="root"
DATABASE_PASSWORD="password"  # Replace with your database password

# Install necessary packages
sudo apt update
sudo apt install -y curl git unzip nginx mysql-server php-fpm php-mysql php-mbstring php-json php-gd php-curl php-zip php-bcmath

# Create a directory for Pterodactyl
mkdir -p /opt/pterodactyl
cd /opt/pterodactyl

# Download and extract Pterodactyl
wget -nv https://github.com/Pterodactyl/Panel/releases/download/v1.10.0/Panel-1.10.0.zip
unzip Panel-1.10.0.zip
rm Panel-1.10.0.zip

# Configure Ngrok
echo "Setting Ngrok auth token..."
ngrok authtoken $NGROK_AUTH_TOKEN

# Configure the database
echo "Configuring database..."
mysql -u $DATABASE_USER -p$DATABASE_PASSWORD -e "CREATE DATABASE IF NOT EXISTS $DATABASE_NAME;"
mysql -u $DATABASE_USER -p$DATABASE_PASSWORD -e "GRANT ALL PRIVILEGES ON $DATABASE_NAME.* TO '$DATABASE_USER'@'%' IDENTIFIED BY '$DATABASE_PASSWORD';"

# Configure Pterodactyl
echo "Configuring Pterodactyl..."
cp ./config.example.php ./config.php
sed -i "s/DB_HOST = 'localhost'/DB_HOST = '$DATABASE_HOST'/g" ./config.php
sed -i "s/DB_NAME = 'pterodactyl'/DB_NAME = '$DATABASE_NAME'/g" ./config.php
sed -i "s/DB_USER = 'root'/DB_USER = '$DATABASE_USER'/g" ./config.php
sed -i "s/DB_PASS = 'password'/DB_PASS = '$DATABASE_PASSWORD'/g" ./config.php

# Start Pterodactyl
echo "Starting Pterodactyl..."
php artisan key:generate
php artisan migrate --force
php artisan db:seed
php artisan serve --host=0.0.0.0

# Start ngrok tunnel
echo "Starting ngrok tunnel..."
ngrok http 80 &

echo "Pterodactyl is now running at: http://$(ngrok http 80 -c | grep -oE 'https?://[a-z0-9.-]+')"
echo "Installation complete!"
