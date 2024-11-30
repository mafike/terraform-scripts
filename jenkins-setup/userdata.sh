#!/bin/bash
set -e

# Log all output to user data log
exec > >(tee /var/log/userdata.log | logger -t user-data -s 2>/dev/console) 2>&1

# Update and install prerequisites
sudo apt-get -y update
sudo apt-get install -y unzip nfs-common openjdk-11-jdk

# Create Jenkins user and directory
sudo mkdir -p /var/lib/jenkins
sudo groupadd jenkins || true
sudo useradd -m -d /var/lib/jenkins -g jenkins jenkins || true
sudo chown -R jenkins:jenkins /var/lib/jenkins

# Fetch the EFS DNS name and mount the EFS
EFS_DNS="${aws_efs_file_system.JenkinsEFS.dns_name}"
AZ=$(curl -s http://169.254.169.254/latest/meta-data/placement/availability-zone)
FULL_EFS_DNS="${AZ}.${EFS_DNS}"

echo "Attempting to mount EFS: ${FULL_EFS_DNS}"
MAX_RETRIES=10
RETRY_COUNT=0
while ! sudo mount -t nfs4 -o vers=4.1 "${FULL_EFS_DNS}:/" /var/lib/jenkins; do
    echo "EFS mount failed, retrying in 10 seconds..."
    sleep 10
    RETRY_COUNT=$((RETRY_COUNT + 1))
    if [[ $RETRY_COUNT -ge $MAX_RETRIES ]]; then
        echo "EFS mount failed after $MAX_RETRIES attempts. Exiting."
        exit 1
    fi
done
echo "EFS mounted successfully."

# Add EFS to /etc/fstab for persistence
if ! grep -q "${FULL_EFS_DNS}" /etc/fstab; then
    echo "${FULL_EFS_DNS}:/ /var/lib/jenkins nfs defaults,vers=4.1 0 0" | sudo tee -a /etc/fstab
    echo "EFS entry added to /etc/fstab."
else
    echo "EFS entry already exists in /etc/fstab."
fi

# Install Jenkins
sudo wget -q -O - https://pkg.jenkins.io/debian-stable/jenkins.io.key | sudo apt-key add -
echo "deb https://pkg.jenkins.io/debian-stable binary/" | sudo tee /etc/apt/sources.list.d/jenkins.list
sudo apt-get -y update
sudo apt-get -y install jenkins

# Enable and start Jenkins service
sudo systemctl daemon-reload
sudo systemctl enable jenkins
sudo systemctl start jenkins
echo "Jenkins has been installed and started."
