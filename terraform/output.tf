output "cluster_endpoint" {
  value = aws_eks_cluster.bedrock.endpoint
}

output "cluster_name" {
  value = aws_eks_cluster.bedrock.name
}

output "region" {
  value = "us-east-1"
}

output "vpc_id" {
  value = aws_vpc.main.id

}

output "assets_bucket_name" {
  value = "project-bedrock-state-bucket"
}


# IAM - Developer user credentials
output "dev_user_access_key_id" {
  description = "Access key ID for bedrock-dev-view user"
  value       = aws_iam_access_key.dev_view.id
}

output "dev_user_secret_access_key" {
  description = "Secret access key for bedrock-dev-view user"
  value       = aws_iam_access_key.dev_view.secret
  sensitive   = true
}
