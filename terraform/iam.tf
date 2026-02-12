# =========================================
# IAM for Developer User (Read-Only + S3 + EKS Access)
# =========================================

# -------------------------------
# Reference existing S3 bucket
# -------------------------------
data "aws_s3_bucket" "assets" {
  bucket = "project-bedrock-state-bucket"
}

# -------------------------------
# Create the developer IAM user
# -------------------------------
resource "aws_iam_user" "dev_view" {
  name = "bedrock-dev-view"
}

# -------------------------------
# Attach AWS ReadOnlyAccess policy for console access
# -------------------------------
resource "aws_iam_user_policy_attachment" "dev_view_readonly" {
  user       = aws_iam_user.dev_view.name
  policy_arn = "arn:aws:iam::aws:policy/ReadOnlyAccess"
}

# -------------------------------
# Generate access keys for CLI access
# -------------------------------
resource "aws_iam_access_key" "dev_view" {
  user = aws_iam_user.dev_view.name
}

# -------------------------------
# Allow dev user to upload to assets bucket
# -------------------------------
resource "aws_iam_user_policy" "dev_view_s3_upload" {
  name = "assets-bucket-upload"
  user = aws_iam_user.dev_view.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:PutObject",
          "s3:GetObject",
          "s3:ListBucket"
        ]
        Resource = [
          data.aws_s3_bucket.assets.arn,
          "${data.aws_s3_bucket.assets.arn}/*"
        ]
      }
    ]
  })
}

# ==================================================
# EKS Access (Only valid AFTER enabling API auth)
# ==================================================
# NOTE: You must enable API authentication on your cluster manually before Terraform can create access entries
# AWS CLI example:
# aws eks update-cluster-config --name project-bedrock-cluster-bucket \
#     --access-config authenticationMode=API_AND_CONFIG_MAP

# -------------------------------
# Create EKS access entry for dev user
# -------------------------------
# Uncomment only AFTER enabling API auth
# resource "aws_eks_access_entry" "dev_view" {
#   cluster_name  = aws_eks_cluster.main.name
#   principal_arn = aws_iam_user.dev_view.arn
#   type          = "STANDARD"
# }

# -------------------------------
# Grant read-only access to EKS cluster
# -------------------------------
# resource "aws_eks_access_policy_association" "dev_view" {
#   cluster_name  = aws_eks_cluster.main.name
#   principal_arn = aws_iam_user.dev_view.arn
#   policy_arn    = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSViewPolicy"

#   access_scope {
#     type = "cluster"
#   }

#   depends_on = [aws_eks_access_entry.dev_view]
# }
