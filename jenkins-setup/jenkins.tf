/*provider "aws" {
  region = var.aws_region
}


# Launch Jenkins server instance
resource "aws_instance" "jenkins" {
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = var.instance_type
  subnet_id                   = module.vpc.public_subnets[0]
  associate_public_ip_address = true
  security_groups        = [aws_security_group.jenkins.id]
  key_name                    = aws_key_pair.generated.key_name
  user_data = file("userdata.sh")
  tags = {
    Name  = "Jenkins-Server"
    App   = "Jenkins"
  }

}
*/
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




/*
output "jenkins_endpoint" {
  value = formatlist("http://%s:%s/", aws_instance.Jenkins.*.public_ip, "8090")
} */