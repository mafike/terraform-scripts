# EFS CSI Helm Release Outputs
output "efs_helm_metadata" {
  description = "Metadata Block outlining status of the deployed release."
  value = helm_release.efs_csi_driver.metadata
}

output "efs_csi_iam_role_arn" {
  description = "EFS CSI IAM Role ARN"
  value = aws_iam_role.efs_csi_iam_role.arn
}

##

# Resource: EFS Mount Target
resource "aws_efs_mount_target" "efs_mount_target" {
  #for_each = toset(module.vpc.private_subnets)
  count = 2
  file_system_id = aws_efs_file_system.efs_file_system.id
  subnet_id      = data.terraform_remote_state.eks.outputs.private_subnets[count.index]
  security_groups = [ aws_security_group.efs_allow_access.id ]
}



# EFS File System ID
output "efs_file_system_id" {
  description = "EFS File System ID"
  value = aws_efs_file_system.efs_file_system.id 
}

output "efs_file_system_dns_name" {
  description = "EFS File System DNS Name"
  value = aws_efs_file_system.efs_file_system.dns_name
}


# EFS Mounts Info
output "efs_mount_target_id" {
  description = "EFS File System Mount Target ID"
  value = aws_efs_mount_target.efs_mount_target[*].id 
}

output "efs_mount_target_dns_name" {
  description = "EFS File System Mount Target DNS Name"
  value = aws_efs_mount_target.efs_mount_target[*].mount_target_dns_name 
}

output "efs_mount_target_availability_zone_name" {
  description = "EFS File System Mount Target availability_zone_name"
  value = aws_efs_mount_target.efs_mount_target[*].availability_zone_name 
}