provider "aws" {
  region = "us-east-1"
  
  # LocalStack configuration
  access_key = "test"
  secret_key = "test"
  
  # Skip authentication for LocalStack
  skip_credentials_validation = true
  skip_metadata_api_check     = true
  skip_requesting_account_id  = true
  
  # LocalStack endpoint
  endpoints {
    apigateway     = "http://localhost:4566"
    dynamodb       = "http://localhost:4566"
    iam            = "http://localhost:4566"
    lambda         = "http://localhost:4566"
    s3             = "http://localhost:4566"
  }
}

# S3 bucket for static assets with server-side encryption (data protection)
resource "aws_s3_bucket" "static_assets" {
  bucket = "demo-static-assets"
  
  # Prevent accidental deletion
  lifecycle {
    prevent_destroy = true
  }
}

# Enable server-side encryption by default
resource "aws_s3_bucket_server_side_encryption_configuration" "example" {
  bucket = aws_s3_bucket.static_assets.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# DynamoDB table
resource "aws_dynamodb_table" "items_table" {
  name           = "demo-items"
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "id"
  
  attribute {
    name = "id"
    type = "S"
  }
}

# IAM role for Lambda
resource "aws_iam_role" "lambda_role" {
  name = "demo-lambda-role"
  
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
}

# Lambda function policy - least privilege principle
resource "aws_iam_role_policy" "lambda_policy" {
  name = "demo-lambda-policy"
  role = aws_iam_role.lambda_role.id
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "dynamodb:GetItem",
          "dynamodb:PutItem",
          "dynamodb:UpdateItem",
          "dynamodb:DeleteItem",
          "dynamodb:Query"
        ]
        Effect   = "Allow"
        Resource = aws_dynamodb_table.items_table.arn
      },
      {
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Effect   = "Allow"
        Resource = "arn:aws:logs:*:*:*"
      }
    ]
  })
}

# Create ZIP file for Lambda code
data "archive_file" "lambda_zip" {
  type        = "zip"
  source_file = "../src/lambda_function.py"
  output_path = "../src/lambda_function.zip"
}

# Lambda function
resource "aws_lambda_function" "api_handler" {
  function_name    = "demo-api-handler"
  role             = aws_iam_role.lambda_role.arn
  handler          = "lambda_function.handler"
  filename         = data.archive_file.lambda_zip.output_path
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256
  runtime          = "python3.9"
  
  environment {
    variables = {
      DYNAMODB_TABLE = aws_dynamodb_table.items_table.name
    }
  }
}

# API Gateway
resource "aws_api_gateway_rest_api" "api" {
  name        = "demo-api"
  description = "Demo API Gateway"
}

# API Gateway resource
resource "aws_api_gateway_resource" "items_resource" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  parent_id   = aws_api_gateway_rest_api.api.root_resource_id
  path_part   = "items"
}

# API Gateway method
resource "aws_api_gateway_method" "items_post" {
  rest_api_id   = aws_api_gateway_rest_api.api.id
  resource_id   = aws_api_gateway_resource.items_resource.id
  http_method   = "POST"
  authorization_type = "NONE"
}

# API Gateway integration
resource "aws_api_gateway_integration" "lambda_integration" {
  rest_api_id             = aws_api_gateway_rest_api.api.id
  resource_id             = aws_api_gateway_resource.items_resource.id
  http_method             = aws_api_gateway_method.items_post.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.api_handler.invoke_arn
}

# API Gateway deployment
resource "aws_api_gateway_deployment" "deployment" {
  depends_on = [aws_api_gateway_integration.lambda_integration]
  
  rest_api_id = aws_api_gateway_rest_api.api.id
  stage_name  = "dev"
}

# Lambda permission for API Gateway
resource "aws_lambda_permission" "api_gateway_permission" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.api_handler.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.api.execution_arn}/*/${aws_api_gateway_method.items_post.http_method}${aws_api_gateway_resource.items_resource.path}"
}