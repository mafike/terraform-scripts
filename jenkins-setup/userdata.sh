#!/bin/bash
sudo apt-get -y update
sudo apt-get install -y unzip
sudo apt-get install -y nfs-common
sudo mkdir -p /var/lib/jenkins
sudo adduser -m -d /var/lib/jenkins jenkins
sudo groupadd jenkins
sudo usermod -a -G jenkins jenkins
sudo chown -R jenkins:jenkins /var/lib/jenkins
while ! (sudo mount -t nfs4 -o vers=4.1 $(curl -s http://169.254.169.254/latest/meta-data/placement/availability-zone).${aws_efs_file_system.JenkinsEFS.dns_name}:/ /var/lib/jenkins); do sleep 10; done
# Edit fstab so EFS automatically loads on reboot
while ! (echo ${aws_efs_file_system.JenkinsEFS.dns_name}:/ /var/lib/jenkins nfs defaults,vers=4.1 0 0 >> /etc/fstab) ; do sleep 10; done
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
