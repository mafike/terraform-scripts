
variable "environment" {
  description = "Environment for deployment"
  type        = string
  default     = "dev"
}

variable "aws_region" {
  type    = string
  default = "us-east-1"
}

variable "vpc_name" {
  type    = string
  default = "jenkins-vpc"
}

variable "vpc_cidr" {
  type    = string
  default = "10.0.0.0/16"
}


variable "availability_zone" {
  type    = string
  default = "us-east-1a"
}

variable "mac_ip" {
  description = "Your Mac's public IP in CIDR format"
  type        = string
  default     = "203.0.113.5/32" # Replace this with your actual IP if not using dynamic input
                                 # terraform apply -var "mac_ip=$(curl -s http://checkip.amazonaws.com)/32"
}

