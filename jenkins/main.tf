
provider "aws" {
  region = var.aws_region
}

/*
module "bastion_outputs" {
  source = "../eks" # Update path if necessary
}
 # if the bastion sg exist
data "aws_security_group" "bastion" {
  filter {
    name   = "group-name"
    values = ["bastion-sg-name"] # Replace with your Bastion SG name
  }
  vpc_id = module.vpc.vpc_id
}
*/

module "vpc" {
  source                       = "../eks/vpc" # Update the path to the VPC module
  vpc_name                     = "jenkins-vpc"
  vpc_cidr_block               = "10.0.0.0/16"
  vpc_public_subnets           = ["10.0.101.0/24", "10.0.102.0/24"]
  vpc_private_subnets          = ["10.0.1.0/24", "10.0.2.0/24"]
  vpc_database_subnets         = ["10.0.151.0/24", "10.0.152.0/24"]
  vpc_enable_nat_gateway       = false
  vpc_single_nat_gateway       = false
  vpc_create_database_subnet_group = false
  vpc_create_database_subnet_route_table = false
  
  eks_cluster_name = "jenkins-cluster" 
  common_tags      = {
    Application = "Jenkins"
    Environment = "Development"
  }
}
# Create Security Group for Jenkins server
resource "aws_security_group" "jenkins" {
  name   = "jenkins-sg"
  vpc_id = module.vpc.vpc_id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
   // security_groups = [module.bastion_outputs.bastion_security_group_id]
   // security_groups = [data.terraform_remote_state.vpc.outputs.bastion_security_group_id]
    cidr_blocks = [var.mac_ip] # SSH access
  }

  ingress {
    from_port   = 8090
    to_port     = 8090
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # Jenkins Web UI
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "jenkins-sg"
  }
}

# Launch Jenkins server instance
resource "aws_instance" "jenkins" {
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = "t2.micro"
 subnet_id                   = module.vpc.public_subnets[0]
  associate_public_ip_address = true
  security_groups        = [aws_security_group.jenkins.id]
  key_name                    = aws_key_pair.generated.key_name

  user_data = <<-EOF
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

  EOF
  

  tags = {
    Name  = "Jenkins-Server"
    App   = "Jenkins"
  }
}

# Generate SSH Key Pair
resource "tls_private_key" "generated" {
  algorithm = "RSA"
}

resource "aws_key_pair" "generated" {
  key_name   = "JenkinsKey"
  public_key = tls_private_key.generated.public_key_openssh
}

resource "local_file" "private_key_pem" {
  content  = tls_private_key.generated.private_key_pem
  filename = "JenkinsKey.pem"
}

# Terraform Data Block - To Lookup Latest Ubuntu 20.04 AMI Image
data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] # Canonical
}
