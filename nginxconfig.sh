#!/bin/bash

# Update package repository information
sudo apt update

# Install Nginx and logrotate
sudo apt install nginx logrotate -y

# Install OpenSSL for generating SSL certificate
sudo apt install openssl -y

# Configure Nginx to use 3 worker processes
sudo sed -i 's/worker_processes auto;/worker_processes 3;/' /etc/nginx/nginx.conf

# Enable access logs and specify log location
sudo sed -i '/^http {/a \    access_log \/var\/log\/nginx\/access.log;' /etc/nginx/nginx.conf

# Create the log directory if it doesn't exist
sudo mkdir -p /var/log/nginx

echo "<html><body><h1>Linux Administration</h1></body></html>" | sudo tee /var/www/html/index.html

# Set appropriate permissions for the HTML file
sudo chown www-data:www-data /var/www/html/index.html
sudo chmod 755 /var/www/html/index.html

# Set memory usage limit for nginx.service to 1GB
echo "DefaultLimitMEMLOCK=1G" | sudo tee -a /etc/systemd/system/nginx.service.d/override.conf

# Generate self-signed SSL certificate and private key
sudo openssl genpkey -algorithm RSA -out onepiece.key
sudo openssl req -new -key onepiece.key -out onepiece.csr
sudo openssl x509 -req -in onepiece.csr -CA ca.crt -CAkey ca.key -CAcreateserial -out onepiece.crt -days 365

# Configure Nginx for SSL
sudo tee /etc/nginx/sites-available/onepiece-ssl <<EOL
server {
    listen 443 ssl;
    server_name onepiece.com;

    ssl_certificate /etc/nginx/CA/onepiece.com.crt;
    ssl_certificate_key /etc/nginx/CA/onepiece.com.key;

    location / {
        root /var/www/html;
        index index.html;
    }

     location /drive {
        root /srv;
	auth_basic "Restricted Access";
        auth_basic_user_file /etc/nginx/.htpasswd;
    }
}
EOL

# Create a symbolic link to enable the site
sudo ln -s /etc/nginx/sites-available/onepiece-ssl /etc/nginx/sites-enabled/

# Remove default configuration
sudo rm /etc/nginx/sites-enabled/default

# Test Nginx configuration
sudo nginx -t

# Restart Nginx to apply changes
sudo systemctl restart nginx
