#!/bin/bash

# Colors for output
GREEN="\e[32m"
YELLOW="\e[33m"
RED="\e[31m"
CYAN="\e[36m"
RESET="\e[0m"

# Ensure the script is run as root
if [ "$EUID" -ne 0 ]; then
  echo -e "${RED}Please run this script as root or use sudo.${RESET}"
  exit 1
fi

# Input parameters
DOCKER_IMAGE=$1
DOMAIN=$2
PORT=${3:-3000}  # Default to port 3000 if not provided

if [ -z "$DOCKER_IMAGE" ] || [ -z "$DOMAIN" ]; then
  echo -e "${YELLOW}Usage: $0 <docker_image> <domain> [port]${RESET}"
  echo -e "Example: $0 bkimminich/juice-shop gallagher-juice-shop.ddnsfree.com 4000"
  exit 1
fi

echo -e "${CYAN}### Starting Deployment for $DOMAIN ###${RESET}"

# Step 1: Update the system
echo -e "${GREEN}Step 1: Updating the system...${RESET}"
apt update -y && apt upgrade -y

# Step 2: Install required packages
echo -e "${GREEN}Step 2: Installing Docker, Nginx, and Certbot...${RESET}"
apt install -y docker.io nginx certbot python3-certbot-nginx

# Step 3: Start and enable Docker service
echo -e "${GREEN}Step 3: Starting and enabling Docker...${RESET}"
systemctl start docker
systemctl enable docker

# Step 4: Pull and run Docker container
echo -e "${GREEN}Step 4: Pulling Docker image ($DOCKER_IMAGE)...${RESET}"
docker pull $DOCKER_IMAGE

echo -e "${GREEN}Running Docker container on port $PORT...${RESET}"
docker run -d --name juice-shop -p $PORT:$PORT $DOCKER_IMAGE

# Step 5: Configure Nginx
echo -e "${GREEN}Step 5: Configuring Nginx for domain $DOMAIN...${RESET}"
NGINX_CONF="/etc/nginx/sites-available/$DOMAIN"
cat <<EOL > $NGINX_CONF
server {
    listen 80;
    server_name $DOMAIN;

    location / {
        proxy_pass http://localhost:$PORT;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host \$host;
        proxy_cache_bypass \$http_upgrade;
    }
}
EOL

ln -s $NGINX_CONF /etc/nginx/sites-enabled/

echo -e "${GREEN}Testing Nginx configuration...${RESET}"
nginx -t
if [ $? -ne 0 ]; then
  echo -e "${RED}Nginx configuration test failed. Exiting.${RESET}"
  exit 1
fi

echo -e "${GREEN}Restarting Nginx...${RESET}"
systemctl reload nginx

# Step 6: Obtain SSL certificate with Certbot
echo -e "${GREEN}Step 6: Obtaining SSL certificate for $DOMAIN...${RESET}"
certbot --nginx -d $DOMAIN --non-interactive --agree-tos -m admin@$DOMAIN
if [ $? -ne 0 ]; then
  echo -e "${RED}Certbot failed to obtain an SSL certificate. Please check your domain and try again.${RESET}"
  exit 1
fi

# Step 7: Verify SSL auto-renewal
echo -e "${GREEN}Step 7: Verifying SSL auto-renewal...${RESET}"
certbot renew --dry-run

# Step 8: Open necessary firewall ports
echo -e "${GREEN}Step 8: Opening necessary firewall ports...${RESET}"
ufw allow 80
ufw allow 443
ufw reload

echo -e "${CYAN}### Deployment Completed Successfully ###${RESET}"
echo -e "Your application is available at: ${CYAN}https://$DOMAIN${RESET}"
