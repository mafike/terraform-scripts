/* resource "null_resource" "wait_for_eks_state" {
  depends_on = [aws_eks_cluster.eks_cluster] # Ensure EKS cluster is created before proceeding
}

data "terraform_remote_state" "eks" {
  depends_on = [null_resource.wait_for_eks_state]

  backend = "local"
  config = {
    path = "/terraform.tfstate"
  }
}
*/