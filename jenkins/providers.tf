
terraform {
  required_version = ">= 1.6.0"
  required_providers {
    aws = {
      source = "hashicorp/aws"
      #version = ">= 4.65"
      version = ">= 5.31"
    }
   tls = {
      source  = "hashicorp/tls"
      version = "3.1.0"
    }
  }
}