# RDS MySQL (for Catalog service)
resource "aws_db_instance" "catalog_mysql" {
  identifier        = "project-bedrock-catalog-mysql"
  engine            = "mysql"
  engine_version    = "8.0"
  instance_class    = "db.t3.micro"
  allocated_storage = 20
  storage_type      = "gp2"

  db_name  = "catalog_db"
  username = "Catalog_usr"
  password = "Ferrari26bedrock$"

  vpc_security_group_ids = [aws_security_group.rds.id]
  db_subnet_group_name   = aws_db_subnet_group.main.name

  skip_final_snapshot = true # For dev/test only
  publicly_accessible = false

  tags = {
    Name = "project-bedrock-catalog-mysql"
  }
}

# RDS PostgresSQL (for Orders service)
resource "aws_db_instance" "orders_postgres" {
  identifier        = "project-bedrock-orders-postgres"
  engine            = "postgres"
  engine_version    = "16"
  instance_class    = "db.t3.micro"
  allocated_storage = 20
  storage_type      = "gp2"

  db_name  = "orders_db"
  username = "Orders_usr"
  password = "F9Lewisferrari"

  vpc_security_group_ids = [aws_security_group.rds.id]
  db_subnet_group_name   = aws_db_subnet_group.main.name

  skip_final_snapshot = true # For dev/test only
  publicly_accessible = false

  tags = {
    Name = "project-bedrock-orders-postgres"
  }
}

# Security group allowing EKS nodes to access RDS
resource "aws_security_group" "rds" {
  name        = "project-bedrock-rds-sg"
  description = "Allow EKS nodes to access RDS"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "MySQL from EKS"
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"]
  }

  ingress {
    description = "PostgreSQL from EKS"
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# RDS Subnet Group
resource "aws_db_subnet_group" "main" {
  name       = "project-bedrock-db-subnet-group"
  subnet_ids = aws_subnet.private[*].id

  tags = {
    Name = "project-bedrock-db-subnet-group"
  }
}

# AWS Secret Manager for Catalog MySQL credentials
resource "aws_secretsmanager_secret" "catalog_db" {
  name = "project-bedrock-catalog-db-credentials"
}

resource "aws_secretsmanager_secret_version" "catalog_db" {
  secret_id = aws_secretsmanager_secret.catalog_db.id
  secret_string = jsonencode({
    username = "Catalog_usr"
    password = "Ferrari26bedrock$"
    database = "catalog_db"
    host     = split(":", aws_db_instance.catalog_mysql.endpoint)[0]
    port     = 3306
  })
}

# AWS Secret Manager for Orders PostgresSQL credentials
resource "aws_secretsmanager_secret" "orders_db" {
  name = "project-bedrock-orders-db-credentials"
}

resource "aws_secretsmanager_secret_version" "orders_db" {
  secret_id = aws_secretsmanager_secret.orders_db.id
  secret_string = jsonencode({
    username = "Orders_usr"
    password = "F9Lewisferrari"
    database = "orders_db"
    host     = split(":", aws_db_instance.orders_postgres.endpoint)[0]
    port     = 5432
  })
}

# IAM Role for Service Account - allows ESO to read from Secrets Manager
resource "aws_iam_role" "eso" {
  name = "project-bedrock-eso-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = aws_iam_openid_connect_provider.eks.arn
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringEquals = {
            "${replace(aws_iam_openid_connect_provider.eks.url, "https://", "")}:sub" = "system:serviceaccount:external-secrets:external-secrets"
            "${replace(aws_iam_openid_connect_provider.eks.url, "https://", "")}:aud" = "sts.amazonaws.com"
          }
        }
      }
    ]
  })
}

# Policy allowing ESO to read secrets from Secrets Manager
resource "aws_iam_role_policy" "eso_secrets" {
  name = "eso-secrets-access"
  role = aws_iam_role.eso.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue",
          "secretsmanager:DescribeSecret"
        ]
        Resource = [
          aws_secretsmanager_secret.catalog_db.arn,
          aws_secretsmanager_secret.orders_db.arn
        ]
      }
    ]
  })
}