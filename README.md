# AWS Terraform Demo with LocalStack

This project demonstrates infrastructure-as-code using Terraform with AWS services locally via LocalStack.

## Architecture

- S3 bucket for static assets (with server-side encryption)
- DynamoDB table for data storage
- Lambda function for request processing
- API Gateway to expose the Lambda function
- IAM roles with least privilege

## Data Protection

This project implements server-side encryption for the S3 bucket to protect static assets at rest.

## Prerequisites

- LocalStack CLI
- Terraform
- AWS CLI
- Python 3.9+

## Getting Started

1. Start LocalStack:
localstack start
2. Initialize Terraform:
cd terraform
terraform init
3. Apply the Terraform configuration:
terraform apply
4. To test the API:
API_URL=$(terraform output -raw api_endpoint)
curl -X POST $API_URL -H "Content-Type: application/json" -d '{"content":"Test item"}'
5. To clean up:
terraform destroy

## Data Protection Highlight
In this project, I've implemented server-side encryption for the S3 bucket as a data protection measure. This ensures that any data stored in the bucket is automatically encrypted at rest using AES-256 encryption. This is an important security practice to:

Protect sensitive data at rest
Meet compliance requirements
Implement defense-in-depth security
Protect against unauthorized access if the storage is compromised