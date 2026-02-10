
resource "aws_instance" "ec2" {
  ami           = "0b6c6ebed2801a5cb"
  instance_type = "t2.micro"
}

resource "aws_eks_cluster" "bedrock" {
  name     = "project-bedrock-cluster"
  role_arn = aws_iam_role.eks_cluster.arn
  version  = "1.34"

  vpc_config {
    subnet_ids = concat(
      aws_subnet.private[*].id,
      aws_subnet.public[*].id
    )
  }
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

resource "aws_eks_node_group" "default" {
  cluster_name    = aws_eks_cluster.bedrock.name
  node_role_arn  = aws_iam_role.eks_node.arn
  subnet_ids     = aws_subnet.private[*].id
  instance_types = ["t2.micro"]

  scaling_config {
    desired_size = 2
    min_size     = 2
    max_size     = 4
  }

  tags = {
    Project = "Bedrock"
  }
}