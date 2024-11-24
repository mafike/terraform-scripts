output "public_url" {
  description = "Public URL for our Web Server"
  value       = "http://${aws_instance.jenkins.public_ip}:8090/"
}

output "vpc_information" {
  description = "VPC Information about Environment"
  value       = "Your ${module.vpc.vpc_id.tags.Environment} VPC has an ID of ${module.vpc.vpc_id}"
}