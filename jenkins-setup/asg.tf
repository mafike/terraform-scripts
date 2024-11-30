
# Create Jenkins server Launch configuration
resource "aws_launch_configuration" "jenkinslc" {
  name                 = "aws_lc-${random_string.suffix.result}"
  image_id             = data.aws_ami.ubuntu.id
  instance_type        = var.instance_type
  iam_instance_profile = aws_iam_instance_profile.ec2_ssm_profile.name
  key_name             = aws_key_pair.generated.key_name
  security_groups      = [aws_security_group.jenkins.id]
  user_data       = <<-EOF
              #!/bin/bash
              set -e

              # Log all output to user data log
              exec > >(tee /var/log/userdata.log | logger -t user-data -s 2>/dev/console) 2>&1
              sudo apt-get -y update
              sudo apt-get install -y nfs-common openjdk-17-jre wget awscli
              # Install Docker
              echo "Installing Docker..."
              curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
              sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
              sudo apt-get -y update
              sudo apt-get install -y docker-ce

              # Install Jenkins
              sudo wget -q -O /usr/share/keyrings/jenkins-keyring.asc https://pkg.jenkins.io/debian-stable/jenkins.io-2023.key
              echo "deb [signed-by=/usr/share/keyrings/jenkins-keyring.asc] https://pkg.jenkins.io/debian-stable binary/" | sudo tee /etc/apt/sources.list.d/jenkins.list > /dev/null
              sudo apt-get -y update
              sudo apt-get -y install jenkins
              # Ensure Jenkins home directory exists
              sudo mkdir -p /var/lib/jenkins
              sudo chown -R jenkins:jenkins /var/lib/jenkins
              # Enable and start Jenkins service
              sudo systemctl daemon-reload
              sudo systemctl enable jenkins
              sudo systemctl start jenkins
              # Add Jenkins user to Docker group
              sudo usermod -aG docker jenkins
              sudo systemctl enable docker
              sudo systemctl start docker
              echo "Docker has been installed and configured."
              # Wait for network to stabilize
              echo "Waiting for network to stabilize..."
              sleep 30
              echo "Jenkins has been installed and started."
              while ! (sudo mount -t nfs4 -o vers=4.1 $(curl -s http://169.254.169.254/latest/meta-data/placement/availability-zone).${aws_efs_file_system.JenkinsEFS.dns_name}:/ /var/lib/jenkins); do sleep 10; done
              # Edit fstab so EFS automatically loads on reboot
              while ! (echo ${aws_efs_file_system.JenkinsEFS.dns_name}:/ /var/lib/jenkins nfs defaults,vers=4.1 0 0 >> /etc/fstab) ; do sleep 10; done
              EOF

  depends_on = [
  aws_efs_file_system.JenkinsEFS]
}
# Create Autoscaling Group using the Launch Configuration jenkinslc
resource "aws_autoscaling_group" "jenkinsasg" {
  name                 = "jenkins_asg"
  launch_configuration = aws_launch_configuration.jenkinslc.name
  vpc_zone_identifier  = module.vpc.public_subnets

  target_group_arns = [aws_lb_target_group.asg.arn]
  health_check_type = "ELB"
  min_size          = 1
  max_size          = 1

  tag {
    key                 = "Name"
    value               = "terraform-asg-jenkins"
    propagate_at_launch = true
  }

  # Create a new instance before deleting the old ones
  lifecycle {
    create_before_destroy = false
  }
}
