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
  source                                 = "../eks/vpc" # Update the path to the VPC module
  vpc_name                               = "jenkins-vpc"
  vpc_cidr_block                         = "10.0.0.0/16"
  vpc_public_subnets                     = ["10.0.101.0/24", "10.0.102.0/24"]
  vpc_private_subnets                    = ["10.0.1.0/24", "10.0.2.0/24"]
  vpc_database_subnets                   = ["10.0.151.0/24", "10.0.152.0/24"]
  vpc_enable_nat_gateway                 = false
  vpc_single_nat_gateway                 = false
  vpc_create_database_subnet_group       = false
  vpc_create_database_subnet_route_table = false

  eks_cluster_name = "jenkins-cluster"
  common_tags = {
    Application = "Jenkins"
    Environment = "Development"
  }
}

output "private_subnets" {
  value = module.vpc.public_subnets # Assuming the VPC module outputs the private subnets
}