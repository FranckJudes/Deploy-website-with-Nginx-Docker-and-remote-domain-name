Voici un **README** complet en Markdown pour configurer votre projet Docker exposé via Nginx et sécurisé avec Certbot.

```markdown
# Juice Shop Docker with Nginx and HTTPS

This guide explains how to deploy the Juice Shop application in a Docker container, expose it via Nginx, and secure it with HTTPS using Certbot.

---

## **Table of Contents**
- [Prerequisites](#prerequisites)
- [Setup Steps](#setup-steps)
  - [Step 1: Clone Juice Shop](#step-1-clone-juice-shop)
  - [Step 2: Run the Docker Container](#step-2-run-the-docker-container)
  - [Step 3: Configure Nginx as a Reverse Proxy](#step-3-configure-nginx-as-a-reverse-proxy)
  - [Step 4: Secure with HTTPS using Certbot](#step-4-secure-with-https-using-certbot)
  - [Step 5: Test the Setup](#step-5-test-the-setup)
- [Troubleshooting](#troubleshooting)
- [Acknowledgments](#acknowledgments)

---

## **Prerequisites**
1. A VPS running Ubuntu (20.04 or newer recommended).
2. A domain name pointing to your VPS (e.g., `gallagher-juice-shop.ddnsfree.com`).
3. Basic knowledge of Docker and Nginx.

---

## **Setup Steps**

### **Step 1: Clone Juice Shop**
Clone the Juice Shop repository to your VPS:
```bash
git clone https://github.com/bkimminich/juice-shop.git
cd juice-shop
```

---

### **Step 2: Run the Docker Container**
Launch the Juice Shop application in a Docker container:
```bash
docker run -d --name juice-shop -p 3000:3000 bkimminich/juice-shop
```

Check if the container is running:
```bash
docker ps
```

Test locally:
```bash
curl http://localhost:3000
```

---

### **Step 3: Configure Nginx as a Reverse Proxy**

#### 1. Install Nginx:
```bash
sudo apt update
sudo apt install nginx -y
```

#### 2. Create a new Nginx configuration:
```bash
sudo nano /etc/nginx/sites-available/gallagher-juice-shop.ddnsfree.com
```

Paste the following configuration:
```nginx
server {
    listen 80;
    server_name gallagher-juice-shop.ddnsfree.com;

    location / {
        proxy_pass http://localhost:3000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_cache_bypass $http_upgrade;
    }
}
```

#### 3. Enable the configuration:
```bash
sudo ln -s /etc/nginx/sites-available/gallagher-juice-shop.ddnsfree.com /etc/nginx/sites-enabled/
sudo nginx -t
sudo systemctl reload nginx
```

#### 4. Test HTTP Access:
Open `http://gallagher-juice-shop.ddnsfree.com` in your browser.

---

### **Step 4: Secure with HTTPS using Certbot**

#### 1. Install Certbot and the Nginx plugin:
```bash
sudo apt install certbot python3-certbot-nginx -y
```

#### 2. Obtain an SSL certificate:
```bash
sudo certbot --nginx -d gallagher-juice-shop.ddnsfree.com
```

Certbot will automatically configure your Nginx server to redirect HTTP to HTTPS.

#### 3. Test HTTPS:
Visit `https://gallagher-juice-shop.ddnsfree.com` in your browser.

#### 4. Verify auto-renewal:
Certbot automatically renews certificates. Test the renewal process:
```bash
sudo certbot renew --dry-run
```

---

### **Step 5: Test the Setup**
1. Access your site via HTTPS: `https://gallagher-juice-shop.ddnsfree.com`.
2. Confirm redirection from HTTP to HTTPS works.

---

## **Troubleshooting**

### Issue: "Domain does not resolve to the VPS"
- Verify that the domain points to your VPS's public IP:
  ```bash
  nslookup gallagher-juice-shop.ddnsfree.com
  ```

### Issue: "Nginx is not responding"
- Check if Nginx is running:
  ```bash
  sudo systemctl status nginx
  ```
- Restart Nginx:
  ```bash
  sudo systemctl restart nginx
  ```

### Issue: "Certbot failed to obtain a certificate"
- Ensure port 80 is open:
  ```bash
  sudo ufw allow 80
  sudo ufw reload
  ```

---

## **Acknowledgments**
- [Juice Shop Project](https://github.com/bkimminich/juice-shop)
- [Certbot](https://certbot.eff.org/)
- [Nginx](https://www.nginx.com/)

---

Enjoy your secure Juice Shop setup! 🎉
