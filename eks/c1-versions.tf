# Terraform Settings Block
terraform {
  required_version = ">= 1.6.0"
  required_providers {
    aws = {
      source = "hashicorp/aws"
      #version = ">= 4.65"
      version = ">= 5.31"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.9"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.16"
    }
  }
}
/*
provider "kubernetes" {
  host                   = data.terraform_remote_state.eks.outputs.cluster_endpoint
  cluster_ca_certificate = base64decode(data.terraform_remote_state.eks.outputs.cluster_certificate_authority_data)
  token                  = data.aws_eks_cluster_auth.cluster.token
}

provider "helm" {
  kubernetes {
    host                   = data.terraform_remote_state.eks.outputs.cluster_endpoint
    cluster_ca_certificate = base64decode(data.terraform_remote_state.eks.outputs.cluster_certificate_authority_data)
    token                  = data.aws_eks_cluster_auth.cluster.token
  }
}

data "aws_eks_cluster" "cluster" {
  name = data.terraform_remote_state.eks.outputs.cluster_id
}

data "aws_eks_cluster_auth" "cluster" {
  name = data.terraform_remote_state.eks.outputs.cluster_id
}
 */
# Terraform Provider Block
provider "aws" {
  region = var.aws_region
}

resource "tls_private_key" "eks_key" {
  algorithm = "RSA"
}

resource "local_file" "eks_private_key" {
  content  = tls_private_key.eks_key.private_key_pem
  filename = "private-key/eks-terraform-key.pem"
}

resource "aws_key_pair" "eks_ssh_key" {
  key_name   = "eks-terraform-key"
  public_key = tls_private_key.eks_key.public_key_openssh
}

