# Output: AWS IAM Open ID Connect Provider
output "aws_iam_openid_connect_provider_extract_from_arn" {
  description = "AWS IAM Open ID Connect Provider extract from ARN"
   value = local.aws_iam_oidc_connect_provider_extract_from_arn
}

# Output: AWS IAM Open ID Connect Provider ARN
output "aws_iam_openid_connect_provider_arn" {
  description = "AWS IAM Open ID Connect Provider ARN"
  value = aws_iam_openid_connect_provider.oidc_provider.arn 
}

