#!/bin/bash
# Install Docker
yum update -y
amazon-linux-extras install docker -y
service docker start
usermod -a -G docker ec2-user

# Install Docker Compose
curl -L "https://github.com/docker/compose/releases/download/1.29.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose

# Install additional dependencies
yum install -y git unzip

# Create app directory
mkdir -p /app
cd /app

# Download and unzip the application code
wget https://github.com/revglen/Infra-aws-assignment/archive/refs/heads/main.zip -O /tmp/app.zip
unzip /tmp/app.zip -d /tmp
mv /tmp/Infra-aws-assignment-main/* .
rm -rf /tmp/app.zip /tmp/Infra-aws-assignment-main

DB_URL="postgresql://${db_username}:${db_password}@${db_endpoint}/${db_name}"
docker build --build-arg DB_URL="$DB_URL" -t ecommerce-app .

# Create docker-compose file
cat > docker-compose.yml <<EOF
version: '3.8'
services:
  app:
    image: ecommerce-app:latest
    environment:
      - DATABASE_URL=postgresql://${db_username}:${db_password}@${db_endpoint}/${db_name}
    ports:
      - "80:8080"
    restart: unless-stopped
EOF

# Start application
docker-compose up -d