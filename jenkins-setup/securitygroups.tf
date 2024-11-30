# Configure Security Group
# Create Security Group for Jenkins server
resource "aws_security_group" "jenkins" {
  name   = "jenkins-sg"
  vpc_id = module.vpc.vpc_id
  ingress {
    from_port = 22
    to_port   = 22
    protocol  = "tcp"
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

  ingress {
    from_port   = 2049
    to_port     = 2049
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
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

# Add security group for EFS
resource "aws_security_group" "ingress-efs" {
  name   = "ingress-efs"
  vpc_id = module.vpc.vpc_id

  ingress {

    from_port   = 2049
    to_port     = 2049
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

#Security group for ALB

resource "aws_security_group" "albSG" {
  name   = "ALB-SG"
  vpc_id = module.vpc.vpc_id

  # Allow inbound HTTP requests
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow all outbound requests
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}