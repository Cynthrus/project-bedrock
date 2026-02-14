# 🚀 Project Bedrock

Production-style cloud-native microservices deployment on AWS using **Terraform**, **Amazon EKS**, and **Helm**.

---

## 📖 Overview

**Project Bedrock** is an Infrastructure-as-Code driven deployment of a distributed retail microservices application on AWS.

The project provisions the full cloud infrastructure using Terraform and deploys containerized services to Amazon EKS using Helm charts from AWS Public ECR.

This project demonstrates real-world DevOps and platform engineering practices including:

- Kubernetes orchestration (EKS)
- Multi-database architecture
- Secrets management
- Event-driven integration (S3 → Lambda)
- Observability integration
- Secure IAM configuration
- Helm-based microservices deployment
- Production-style troubleshooting and recovery

---

# 🏗 Architecture Overview

## Infrastructure Layer (Provisioned with Terraform)

- Amazon EKS Cluster
- Managed Node Groups
- Amazon RDS (MySQL & PostgreSQL)
- Amazon DynamoDB
- Amazon ElastiCache (Redis)
- Amazon S3
- AWS Lambda
- AWS Secrets Manager
- IAM Roles & Policies
- CloudWatch Observability Add-on

---

# 🧩 Application Stack

Retail Store Sample application deployed in the `retail-app` namespace.

| Service   | Persistence Layer | Messaging | Helm Chart |
|------------|------------------|------------|------------|
| Catalog    | MySQL (RDS)      | —          | retail-store-sample-catalog |
| Cart       | DynamoDB         | —          | retail-store-sample-cart |
| Orders     | PostgreSQL (RDS) | RabbitMQ   | retail-store-sample-orders |
| Checkout   | Redis            | —          | retail-store-sample-checkout |
| UI         | Connects to all services | — | retail-store-sample-ui |

---

# ⚙ Infrastructure as Code (Terraform)

## 🔹 EKS Cluster
- Fully managed Amazon EKS cluster
- Managed node group configuration
- Namespace isolation (`retail-app`)
- CloudWatch observability add-on enabled

---

## 🔹 Database Strategy

This project uses multiple data stores to simulate real-world architecture patterns:

- MySQL → Catalog Service
- PostgreSQL → Orders Service
- DynamoDB → Cart Service
- Redis → Checkout Service

Secrets are stored securely in AWS Secrets Manager and referenced dynamically.

---

## 🔹 S3 + Lambda Integration

- Private S3 bucket for marketing assets
- Versioning enabled
- Public access fully blocked
- Lambda function triggered on object upload
- IAM role configured with least privilege
- CloudWatch logging enabled

---

# 🔐 Security Design

- No hardcoded credentials
- Secrets stored in AWS Secrets Manager
- IAM least-privilege policies
- S3 public access blocked
- Namespace-level isolation in Kubernetes
- Controlled security group access for RDS
- Lambda execution role scoped to logging and S3 access

---

# 🚀 Deployment Strategy

Project Bedrock follows a **progressive, modular deployment strategy**:

---

## 1️⃣ Infrastructure First

All infrastructure components are provisioned using Terraform:

```bash
terraform init
terraform plan
terraform apply
