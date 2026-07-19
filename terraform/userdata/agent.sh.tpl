#!/bin/bash

set -e

echo "========================================="
echo " Setting up Jenkins Agent "
echo "========================================="

# --------------------------------------------------
# Update Ubuntu Packages
# --------------------------------------------------

apt-get update -y

# --------------------------------------------------
# Install Java
# --------------------------------------------------

apt-get install -y fontconfig openjdk-21-jre

java -version

# --------------------------------------------------
# Install Docker
# --------------------------------------------------

apt-get install -y docker.io

systemctl enable docker

systemctl start docker

usermod -aG docker ubuntu

systemctl restart docker

# --------------------------------------------------
# Install Git
# --------------------------------------------------

apt-get install -y git

# --------------------------------------------------
# Install Docker Compose Plugin
# --------------------------------------------------

apt-get install -y docker-compose-v2

# --------------------------------------------------
# Create Jenkins Workspace
# --------------------------------------------------

mkdir -p /home/ubuntu/jenkins

chown -R ubuntu:ubuntu /home/ubuntu/jenkins

# --------------------------------------------------
# Configure SSH
# --------------------------------------------------

mkdir -p /home/ubuntu/.ssh

chmod 700 /home/ubuntu/.ssh

cat <<EOF >> /home/ubuntu/.ssh/authorized_keys
${controller_public_key}
EOF

chmod 600 /home/ubuntu/.ssh/authorized_keys

chown -R ubuntu:ubuntu /home/ubuntu/.ssh

echo "========================================="
echo " Jenkins Agent Setup Completed "
echo "========================================="