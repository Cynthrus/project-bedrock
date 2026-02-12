terraform {
  backend "s3" {
    bucket       = "project-bedrock-state-bucket"
    key          = "terraform.tfstate"
    region       = "us-east-1"
    use_lockfile = false
  }
}