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
  value = aws_vpc.bedrock.id
}

output "assets_bucket_name" {
  value = aws_s3_bucket.assets.bucket
}