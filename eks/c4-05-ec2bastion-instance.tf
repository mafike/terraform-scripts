# AWS EC2 Instance Terraform Module
# Bastion Host - EC2 Instance that will be created in VPC Public Subnet
module "ec2_public" {
  depends_on = [aws_key_pair.eks_ssh_key]
  source     = "terraform-aws-modules/ec2-instance/aws"
  #version = "5.0.0"  
  version = "5.5.0"
  # insert the required variables here
  name          = "${local.name}-BastionHost"
  ami           = data.aws_ami.amzlinux2.id
  instance_type = var.instance_type
  key_name      = var.instance_keypair
  #monitoring             = true
  subnet_id              = module.vpc.public_subnets[0]
  vpc_security_group_ids = [module.public_bastion_sg.security_group_id]
  tags                   = local.common_tags

}

module "vpc" {
  source = "./vpc"

  eks_cluster_name = local.eks_cluster_name
  common_tags      = local.common_tags
  # Other variables
}



# Create the directory for the private key
resource "null_resource" "create_directory" {
  provisioner "local-exec" {
    command = "mkdir -p ${path.module}/private-key"
  }
}

resource "tls_private_key" "eks_key" {
  algorithm = "RSA"
  rsa_bits  = 2048
}
# Save the private key locally
resource "local_file" "eks_private_key" {
  content  = tls_private_key.eks_key.private_key_pem
  filename = "${path.module}/private-key/eks-terraform-key.pem"

  depends_on = [null_resource.create_directory]
}

# Create the AWS key pair with the public key
resource "aws_key_pair" "eks_ssh_key" {
  key_name   = "eks-terraform-key"
  public_key = tls_private_key.eks_key.public_key_openssh
}