#!/bin/bash

# Set  desired hostname
NEW_HOSTNAME="jenkins"

# Install Jenkins
sudo wget -O /usr/share/keyrings/jenkins-keyring.asc \
  https://pkg.jenkins.io/debian-stable/jenkins.io-2023.key
echo "deb [signed-by=/usr/share/keyrings/jenkins-keyring.asc] \
  https://pkg.jenkins.io/debian-stable binary/" | sudo tee \
  /etc/apt/sources.list.d/jenkins.list > /dev/null

sudo apt-get update && sudo apt update
sudo apt install fontconfig openjdk-17-jre -y
sudo apt-get install jenkins -y
sudo apt-get install maven -y

# Change Jenkins port from 8080 to 8090 in the systemd service file
sudo sed -i 's/Environment="JENKINS_PORT=8080"/Environment="JENKINS_PORT=8090"/' /usr/lib/systemd/system/jenkins.service

# Change the port in the default configuration file as well
sudo sed -i 's/^HTTP_PORT=8080/HTTP_PORT=8090/' /etc/default/jenkins

# Change the hostname
sudo hostnamectl set-hostname $NEW_HOSTNAME
echo "$NEW_HOSTNAME" | sudo tee -a /etc/hosts

# Reload systemd configuration
sudo systemctl daemon-reload

# Start Jenkins service
sudo systemctl restart jenkins

echo "Jenkins has been installed and started on port 8090."
echo "Hostname set to $NEW_HOSTNAME."
