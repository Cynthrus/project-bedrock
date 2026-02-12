# =========================================
# IAM Roles
# =========================================

# IAM Role for the EKS Cluster (Control Plane)
resource "aws_iam_role" "eks_cluster" {
  name = "project-bedrock-cluster-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "eks.amazonaws.com"
        }
      }
    ]
  })
}

# IAM Role for Node Group (EC2 Worker Nodes)
resource "aws_iam_role" "eks_nodes" {
  name = "project-bedrock-node-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
}

# Attach required policies for cluster
resource "aws_iam_role_policy_attachment" "eks_cluster_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.eks_cluster.name
}

# Attach required policies for nodes
resource "aws_iam_role_policy_attachment" "eks_worker_node_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.eks_nodes.name
}

resource "aws_iam_role_policy_attachment" "eks_cni_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.eks_nodes.name
}

resource "aws_iam_role_policy_attachment" "eks_ecr_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.eks_nodes.name
}

# =========================================
# EKS Cluster
# =========================================

resource "aws_eks_cluster" "main" {
  name     = "project-bedrock-cluster-bucket"
  version  = "1.34"
  role_arn = aws_iam_role.eks_cluster.arn

  vpc_config {
    subnet_ids = concat(
      aws_subnet.public[*].id,
      aws_subnet.private[*].id
    )
  }

  enabled_cluster_log_types = [
    "api",
    "audit",
    "authenticator",
    "controllerManager",
    "scheduler"
  ]

  depends_on = [
    aws_iam_role_policy_attachment.eks_cluster_policy
  ]
}

# =========================================
# EKS Node Group
# =========================================

resource "aws_eks_node_group" "main" {
  cluster_name    = aws_eks_cluster.main.name
  node_group_name = "project-bedrock-node-group"
  node_role_arn   = aws_iam_role.eks_nodes.arn
  subnet_ids      = aws_subnet.private[*].id
  instance_types  = ["t2.micro"]

  scaling_config {
    desired_size = 2
    min_size     = 2
    max_size     = 2
  }

  depends_on = [
    aws_iam_role_policy_attachment.eks_worker_node_policy,
    aws_iam_role_policy_attachment.eks_cni_policy,
    aws_iam_role_policy_attachment.eks_ecr_policy
  ]
}

# =========================================
# Notes on Access Entries
# =========================================
# Terraform cannot enable API authentication for the cluster.
# To use aws_eks_access_entry:
# 1. Enable API or API_AND_CONFIG_MAP auth via AWS CLI:
#    aws eks update-cluster-config --name project-bedrock-cluster-bucket \
#        --access-config authenticationMode=API_AND_CONFIG_MAP
# 2. Then you can create access entries for IAM users/roles.
#
# Example (after enabling API auth):
# resource "aws_eks_access_entry" "dev_view" {
#   cluster_name  = aws_eks_cluster.main.name
#   principal_arn = aws_iam_user.dev_view.arn
#   type          = "STANDARD"
# }

# Get TLS certificate from EKS OIDC issuer URL (needed for thumbprint validation)
data "tls_certificate" "eks" {
  url = aws_eks_cluster.main.identity[0].oidc[0].issuer
}

# Register EKS OIDC provider with IAM (allows pods to assume IAM roles via service accounts)
resource "aws_iam_openid_connect_provider" "eks" {
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.eks.certificates[0].sha1_fingerprint]
  url             = aws_eks_cluster.main.identity[0].oidc[0].issuer
}