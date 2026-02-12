resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "project-bedrock-vpc" # project-bedrock-vpc
  }
}

# Data source to fetch available AZs in the current region
data "aws_availability_zones" "available" {
  state = "available"
}

# Local variable to limit deployment to 2 availability zones
locals {
  azs = slice(data.aws_availability_zones.available.names, 0, 2)
}

# Public Subnets
resource "aws_subnet" "public" {
  count                   = 2
  vpc_id                  = aws_vpc.main.id
  cidr_block              = ["10.0.1.0/24", "10.0.2.0/24"][count.index]
  availability_zone       = local.azs[count.index]
  map_public_ip_on_launch = true

  tags = {
    Name = "project-bedrock-public-subnet-${count.index + 1}"

    "kubernetes.io/role/elb"                         = "1"
    "kubernetes.io/cluster/project-bedrock-cluster"  = "shared"
  }
}

# Private Subnets
resource "aws_subnet" "private" {
  count             = 2
  vpc_id            = aws_vpc.main.id
  cidr_block        = ["10.0.3.0/24", "10.0.4.0/24"][count.index]
  availability_zone = local.azs[count.index]

  tags = {
    Name = "project-bedrock-private-subnet-${count.index + 1}"

    "kubernetes.io/role/internal-elb"                = "1"
    "kubernetes.io/cluster/project-bedrock-cluster" = "shared"
  }
}

# Internet Gateway
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "project-bedrock-igw"
  }
}

# Elastic IP - Static public IP address for NAT Gateway
resource "aws_eip" "nat" {
  domain = "vpc"

  tags = {
    Name = "project-bedrock-nat-eip"
  }
}

# NAT Gateway
resource "aws_nat_gateway" "main" {
  subnet_id     = aws_subnet.public[0].id
  allocation_id = aws_eip.nat.id

  tags = {
    Name = "project-bedrock-nat-gw"
  }

  depends_on = [aws_internet_gateway.main]
}

# Public RT
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = {
    Name = "project-bedrock-public-rt"
  }
}

# Private RT
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.main.id
  }

  tags = {
    Name = "project-bedrock-private-rt"
  }
}

# Public Route Table Associations - Associates public subnets with public route table
resource "aws_route_table_association" "public" {
  count          = 2
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

# Private Route Table Associations - Associates private subnets with private route table
resource "aws_route_table_association" "private" {
  count          = 2
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private.id
}