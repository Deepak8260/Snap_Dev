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
# Copy Jenkinsfile for Bootstrap
# --------------------------------------------------

mkdir -p /var/lib/jenkins/bootstrap

cp /home/ubuntu/Snap_Dev/jenkins/Jenkinsfile-compose \
   /var/lib/jenkins/bootstrap/

chown -R jenkins:jenkins /var/lib/jenkins/bootstrap
chmod -R 755 /var/lib/jenkins/bootstrap

# --------------------------------------------------
# Step 7: Prepare JCasC Directory
# --------------------------------------------------

echo "[7/11] Preparing Jenkins Configuration as Code..."

mkdir -p /var/lib/jenkins/casc_configs

cp -r /home/ubuntu/Snap_Dev/jcasc/* /var/lib/jenkins/casc_configs/

chown -R jenkins:jenkins /var/lib/jenkins/casc_configs

chmod -R 755 /var/lib/jenkins/casc_configs

# --------------------------------------------------
# Copy Groovy Initialization Scripts
# --------------------------------------------------

echo "Copying Groovy initialization scripts..."

mkdir -p /var/lib/jenkins/init.groovy.d

cp -r /home/ubuntu/Snap_Dev/init.groovy.d/* \
/var/lib/jenkins/init.groovy.d/

chown -R jenkins:jenkins /var/lib/jenkins/init.groovy.d


# --------------------------------------------------
# Step 8: Install Jenkins Plugins
# --------------------------------------------------

echo "[8/11] Installing Jenkins Plugins..."


wget -q \
https://github.com/jenkinsci/plugin-installation-manager-tool/releases/download/2.13.2/jenkins-plugin-manager-2.13.2.jar \
-O /opt/jenkins-plugin-manager.jar

mkdir -p /var/lib/jenkins/plugins

java -jar /opt/jenkins-plugin-manager.jar \
    --war /usr/share/java/jenkins.war \
    --plugin-file /var/lib/jenkins/casc_configs/plugins.txt \
    --plugin-download-directory /var/lib/jenkins/plugins


chown -R jenkins:jenkins /var/lib/jenkins/plugins

# --------------------------------------------------
# Step 9: Configure Jenkins Environment
# --------------------------------------------------

echo "[9/11] Configuring Jenkins Environment..."

mkdir -p /etc/systemd/system/jenkins.service.d

cat <<EOF >/etc/systemd/system/jenkins.service.d/override.conf
[Service]
Environment="JAVA_OPTS=-Djava.awt.headless=true -Djenkins.install.runSetupWizard=false"

Environment="JENKINS_ADMIN_USERNAME=${jenkins_admin_username}"
Environment="JENKINS_ADMIN_PASSWORD=${jenkins_admin_password}"

Environment="GITHUB_USERNAME=${github_username}"
Environment="GITHUB_TOKEN=${github_token}"

Environment="DOCKERHUB_USERNAME=${dockerhub_username}"
Environment="DOCKERHUB_PASSWORD=${dockerhub_password}"

Environment="AGENT_NAME=${agent_name}"
Environment="AGENT_LABELS=${agent_labels}"
Environment="AGENT_REMOTE_FS=${agent_remote_fs}"
Environment="AGENT_EXECUTORS=${agent_executors}"
Environment="AGENT_PRIVATE_IP=${agent_private_ip}"

Environment="SMTP_SERVER=${smtp_server}"
Environment="SMTP_PORT=${smtp_port}"
Environment="SMTP_USERNAME=${smtp_username}"
Environment="SMTP_PASSWORD=${smtp_password}"
Environment="SMTP_SSL=${smtp_ssl}"
Environment="ADMIN_EMAIL=${admin_email}"

Environment="CASC_JENKINS_CONFIG=/var/lib/jenkins/casc_configs"
EOF

# ------------------------------------------
# Write SSH Private Key to File
# ------------------------------------------

mkdir -p /var/lib/jenkins/secrets

cat <<EOF >/var/lib/jenkins/secrets/agent_key
${agent_ssh_private_key}
EOF

chmod 600 /var/lib/jenkins/secrets/agent_key
chown jenkins:jenkins /var/lib/jenkins/secrets/agent_key

# --------------------------------------------------
# Step 10: Enable and Start Jenkins
# --------------------------------------------------

echo "[10/11] Starting Jenkins..."

systemctl daemon-reload
systemctl enable jenkins
systemctl stop jenkins || true
systemctl start jenkins

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