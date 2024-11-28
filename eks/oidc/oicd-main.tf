# Datasource: AWS Partition
# Use this data source to lookup information about the current AWS partition in which Terraform is working
data "aws_partition" "current" {}
# Extract the thumbprint dynamically
data "tls_certificate" "oidc_cert" {
  url = data.aws_eks_cluster.eks_cluster.identity[0].oidc[0].issuer
}

data "aws_eks_cluster" "eks_cluster" {
  name = data.terraform_remote_state.eks.outputs.cluster_name
}


# Resource: AWS IAM Open ID Connect Provider
resource "aws_iam_openid_connect_provider" "oidc_provider" {
  client_id_list  = ["sts.${data.aws_partition.current.dns_suffix}"]
  thumbprint_list = [data.tls_certificate.oidc_cert.certificates[0].sha1_fingerprint]
  url             = data.aws_eks_cluster.eks_cluster.identity[0].oidc[0].issuer

  tags = merge(
    {
      Name = "${data.aws_eks_cluster.eks_cluster.name}-eks-irsa"
    },
    local.common_tags
  )
}

