#!/bin/bash

# -------------------------------------------------
# Jenkins Automated Installation Script
# Installs Java (OpenJDK 21) and Jenkins LTS
# Compatible with Ubuntu 24.04
# -------------------------------------------------

set -e

echo "========================================="
echo " Starting Jenkins Installation Setup "
echo "========================================="

# ------------------------------
# Step 1: Update Package Index
# ------------------------------
echo "[1/6] Updating system packages..."
apt update -y

# ------------------------------
# Step 2: Install Java
# ------------------------------
echo "[2/6] Installing OpenJDK 21..."
apt install -y fontconfig openjdk-21-jre

echo "Checking Java installation..."
java -version

# ------------------------------
# Step 3: Add Jenkins Repository Key
# ------------------------------
echo "[3/6] Adding Jenkins repository key..."

mkdir -p /etc/apt/keyrings

wget -O /etc/apt/keyrings/jenkins-keyring.asc \
https://pkg.jenkins.io/debian-stable/jenkins.io-2026.key

# ------------------------------
# Step 4: Add Jenkins Repository
# ------------------------------
echo "[4/6] Adding Jenkins repository..."

echo "deb [signed-by=/etc/apt/keyrings/jenkins-keyring.asc] https://pkg.jenkins.io/debian-stable binary/" \
> /etc/apt/sources.list.d/jenkins.list

# ------------------------------
# Step 5: Install Jenkins
# ------------------------------
echo "[5/6] Installing Jenkins..."

apt update -y
apt install -y jenkins

# ------------------------------
# Step 6: Start Jenkins Service
# ------------------------------
echo "[6/6] Enabling and starting Jenkins..."

systemctl enable jenkins
systemctl start jenkins

echo ""
echo "========================================="
echo " Jenkins Installation Completed "
echo "========================================="

echo "Checking Jenkins service status..."
systemctl status jenkins --no-pager

echo ""
echo "Access Jenkins at:"
echo "http://<your-server-ip>:8080"
echo ""

echo "Initial Admin Password:"
echo "--------------------------------"
cat /var/lib/jenkins/secrets/initialAdminPassword
echo "--------------------------------"