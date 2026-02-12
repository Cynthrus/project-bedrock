# --------------------
# EC2 Instance (standalone)
# --------------------
resource "aws_instance" "ec2" {
  ami           = "ami-0b6c6ebed2801a5cb"
  instance_type = "t3.medium"

  tags = {
    Name    = "bedrock-ec2"
    Project = "Bedrock"
  }
}

# --------------------
# EKS Cluster
# --------------------
resource "aws_eks_cluster" "bedrock" {
  name     = "project-bedrock-cluster"
  role_arn = aws_iam_role.eks_cluster.arn
  version  = "1.29"

  vpc_config {
    subnet_ids = concat(
      aws_subnet.private[*].id,
      aws_subnet.public[*].id
    )
  }

  enabled_cluster_log_types = [
    "api",
    "audit",
    "authenticator",
    "controllerManager",
    "scheduler"
  ]

  tags = {
    Project = "Bedrock"
  }
}

# --------------------
# EKS Node Group
# --------------------
resource "aws_eks_node_group" "default" {
  cluster_name  = aws_eks_cluster.bedrock.name
  node_role_arn = aws_iam_role.eks_node.arn
  subnet_ids    = aws_subnet.private[*].id

  instance_types = ["t3.medium"]

  scaling_config {
    desired_size = 2
    min_size     = 2
    max_size     = 2
  }

  tags = {
    Project = "Bedrock"
  }
}

resource "aws_iam_role" "eks_node" {
  name = "bedrock-eks-node-role"

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

# Attach the Amazon EKS Worker Node policies
resource "aws_iam_role_policy_attachment" "eks_worker_attach" {
  role       = aws_iam_role.eks_node.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
}

resource "aws_iam_role_policy_attachment" "eks_cni_attach" {
  role       = aws_iam_role.eks_node.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
}

resource "aws_iam_role_policy_attachment" "eks_registry_attach" {
  role       = aws_iam_role.eks_node.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}
