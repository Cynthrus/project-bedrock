terraform {
  backend "s3" {
    bucket         = "bedrock-terraform-state- ALT/SOE/025/1390"
    key            = "eks/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "bedrock-terraform-locks"
    encrypt        = true
  }
}