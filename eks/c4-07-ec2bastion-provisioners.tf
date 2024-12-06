# Create a Null Resource and Provisioners
resource "null_resource" "copy_ec2_keys" {
  depends_on = [module.ec2_public, null_resource.create_directory, module.public_bastion_sg, null_resource.create_output_directory]

  # Connection Block for Provisioners to connect to EC2 Instance
  connection {
    type        = "ssh"
    host        = aws_eip.bastion_eip.public_ip
    user        = "ec2-user"
    private_key = tls_private_key.eks_key.private_key_pem # Directly use the private key here
  }

  ## File Provisioner: Copies the private key to the EC2 instance
  provisioner "file" {
    content     = tls_private_key.eks_key.private_key_pem # Use content directly instead of a file
    destination = "/home/ec2-user/eks-terraform-key.pem"
  }

  ## Remote Exec Provisioner: Using remote-exec provisioner to fix the private key permissions on Bastion Host
  provisioner "remote-exec" {
    inline = [
      "sudo chmod 400 /home/ec2-user/eks-terraform-key.pem"
    ]
  }

  ## Local Exec Provisioner: local-exec provisioner (Creation-Time Provisioner - Triggered during Create Resource)
  provisioner "local-exec" {
    command     = "echo VPC created on `date` and VPC ID: ${module.vpc.vpc_id} >> creation-time-vpc-id.txt"
    working_dir = "local-exec-output-files/"
    # on_failure = continue
  }
}
resource "null_resource" "create_output_directory" {
  provisioner "local-exec" {
    command = "mkdir -p local-exec-output-files"
  }
}
