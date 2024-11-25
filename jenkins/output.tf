output "public_url" {
  description = "Public URL for our Web Server"
  value       = "http://${aws_instance.jenkins.public_ip}:8090/"
}
