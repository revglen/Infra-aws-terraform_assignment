#!/bin/bash
yum update -y
amazon-linux-extras install nginx1 -y

# Configure NGINX as reverse proxy
cat > /etc/nginx/conf.d/reverse-proxy.conf <<EOF
upstream app_servers {
    server ${app_alb_dns_name};
}

server {
    listen 80;
    
    location / {
        proxy_pass http://app_servers;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
    }
    
    location /health {
        return 200 'OK';
        add_header Content-Type text/plain;
    }
}
EOF

# Start NGINX
systemctl start nginx
systemctl enable nginx