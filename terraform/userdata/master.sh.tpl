#!/bin/bash

# -------------------------------------------------
# Jenkins Automated Installation Script
# Installs Java, Git and Jenkins
# Configures Jenkins Configuration as Code (JCasC)
# Compatible with Ubuntu 24.04
# -------------------------------------------------

set -e

echo "========================================="
echo " Starting Jenkins Installation Setup "
echo "========================================="

# --------------------------------------------------
# Step 1: Update Package Index
# --------------------------------------------------

echo "[1/11] Updating system packages..."

apt update -y

# --------------------------------------------------
# Step 2: Install Java
# --------------------------------------------------

echo "[2/11] Installing OpenJDK 21..."

apt install -y fontconfig openjdk-21-jre

java -version

# --------------------------------------------------
# Step 3: Install Git
# --------------------------------------------------

echo "[3/11] Installing Git..."

apt install -y git

git --version

# --------------------------------------------------
# Step 4: Clone Snap_Dev Repository
# --------------------------------------------------

echo "[4/11] Cloning Snap_Dev Repository..."

cd /home/ubuntu

if [ ! -d "/home/ubuntu/Snap_Dev" ]; then
    git clone https://github.com/Deepak8260/Snap_Dev.git
else
    echo "Snap_Dev repository already exists."
fi

# --------------------------------------------------
# Step 5: Add Jenkins Repository
# --------------------------------------------------

echo "[5/11] Adding Jenkins Repository..."

mkdir -p /etc/apt/keyrings

wget -O /etc/apt/keyrings/jenkins-keyring.asc \
https://pkg.jenkins.io/debian-stable/jenkins.io-2026.key

echo "deb [signed-by=/etc/apt/keyrings/jenkins-keyring.asc] https://pkg.jenkins.io/debian-stable binary/" \
> /etc/apt/sources.list.d/jenkins.list

# --------------------------------------------------
# Step 6: Install Jenkins
# --------------------------------------------------

echo "[6/11] Installing Jenkins..."

apt update -y
apt install -y jenkins

# --------------------------------------------------
# Step 7: Prepare JCasC Directory
# --------------------------------------------------

echo "[7/11] Preparing Jenkins Configuration as Code..."

mkdir -p /var/lib/jenkins/casc_configs

cp -r /home/ubuntu/Snap_Dev/jcasc/* /var/lib/jenkins/casc_configs/

chown -R jenkins:jenkins /var/lib/jenkins/casc_configs

chmod -R 755 /var/lib/jenkins/casc_configs

# --------------------------------------------------
# Step 8: Install Jenkins Plugins
# --------------------------------------------------

echo "[8/11] Installing Jenkins Plugins..."

/usr/bin/jenkins-plugin-cli \
    --plugin-file /var/lib/jenkins/casc_configs/plugins.txt

# --------------------------------------------------
# Step 9: Configure Jenkins Environment
# --------------------------------------------------

echo "[9/11] Configuring Jenkins Environment..."

cat <<EOF >/etc/default/jenkins
JENKINS_ADMIN_USERNAME=${jenkins_admin_username}
JENKINS_ADMIN_PASSWORD=${jenkins_admin_password}

GITHUB_USERNAME=${github_username}
GITHUB_TOKEN=${github_token}

DOCKERHUB_USERNAME=${dockerhub_username}
DOCKERHUB_PASSWORD=${dockerhub_password}

AGENT_SSH_PRIVATE_KEY='${agent_ssh_private_key}'

AGENT_NAME=${agent_name}
AGENT_LABELS="${agent_labels}"
AGENT_REMOTE_FS=${agent_remote_fs}
AGENT_EXECUTORS=${agent_executors}
AGENT_PRIVATE_IP=${agent_private_ip}

CASC_JENKINS_CONFIG=/var/lib/jenkins/casc_configs
EOF

# --------------------------------------------------
# Step 10: Enable and Start Jenkins
# --------------------------------------------------

echo "[10/11] Starting Jenkins..."

systemctl daemon-reload
systemctl enable jenkins
systemctl restart jenkins

# --------------------------------------------------
# Step 11: Verification
# --------------------------------------------------

echo "[11/11] Verifying Installation..."

echo
echo "========================================="
echo " Jenkins Installation Completed "
echo "========================================="

echo
echo "Jenkins Environment Variables"
echo "--------------------------------"
cat /etc/default/jenkins
echo "--------------------------------"

echo
echo "Installed JCasC Files"
echo "--------------------------------"
ls -la /var/lib/jenkins/casc_configs
echo "--------------------------------"

echo
echo "Checking Jenkins Service..."
systemctl is-active jenkins || true

echo
echo "Access Jenkins at:"
echo "http://<your-server-public-ip>:8080"

echo
echo "If JCasC is configured correctly:"
echo "- No setup wizard should appear."
echo "- Admin user will be created automatically."
echo "- Plugins will already be installed."
echo "- SSH Agent will be configured automatically."