provider "aws" {
  region = "us-east-1"
}

# DynamoDB Table for Prompt Memory and Skill Metadata
resource "aws_dynamodb_table" "hermes_memory" {
  name           = "hermes-memory-vault"
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "AgentId"
  range_key      = "MemoryKey"

  attribute {
    name = "AgentId"
    type = "S"
  }

  attribute {
    name = "MemoryKey"
    type = "S"
  }

  tags = {
    Environment = "Production"
    Project     = "Hermes-Memory-Vault"
  }
}

# S3 Bucket for Skills and SQLite Session Archives
resource "aws_s3_bucket" "hermes_archives" {
  bucket = "hermes-skills-archive-${random_id.bucket_suffix.hex}"
}

resource "random_id" "bucket_suffix" {
  byte_length = 4
}

resource "aws_s3_bucket_versioning" "hermes_archives_versioning" {
  bucket = aws_s3_bucket.hermes_archives.id
  versioning_configuration {
    status = "Enabled"
  }
}

# IAM Role for Lambda
resource "aws_iam_role" "lambda_exec" {
  name = "hermes_memory_lambda_role"

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

# IAM Policy for Lambda to access DynamoDB and S3
resource "aws_iam_role_policy" "lambda_policy" {
  name = "hermes_memory_lambda_policy"
  role = aws_iam_role.lambda_exec.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "dynamodb:PutItem",
          "dynamodb:GetItem",
          "dynamodb:Query"
        ]
        Resource = aws_dynamodb_table.hermes_memory.arn
      },
      {
        Effect = "Allow"
        Action = [
          "s3:PutObject",
          "s3:GetObject"
        ]
        Resource = "${aws_s3_bucket.hermes_archives.arn}/*"
      },
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "arn:aws:logs:*:*:*"
      }
    ]
  })
}

# Lambda Function
resource "aws_lambda_function" "memory_sync" {
  filename         = "lambda_function.zip"
  function_name    = "hermes-memory-sync"
  role             = aws_iam_role.lambda_exec.arn
  handler          = "memory_sync.lambda_handler"
  runtime          = "python3.9"

  environment {
    variables = {
      DYNAMODB_TABLE = aws_dynamodb_table.hermes_memory.name
      S3_BUCKET      = aws_s3_bucket.hermes_archives.id
    }
  }
}

# API Gateway
resource "aws_apigatewayv2_api" "hermes_api" {
  name          = "hermes-memory-api"
  protocol_type = "HTTP"
}

resource "aws_apigatewayv2_integration" "lambda_integration" {
  api_id           = aws_apigatewayv2_api.hermes_api.id
  integration_type = "AWS_PROXY"
  integration_uri  = aws_lambda_function.memory_sync.invoke_arn
}

resource "aws_apigatewayv2_route" "sync_route" {
  api_id    = aws_apigatewayv2_api.hermes_api.id
  route_key = "POST /sync"
  target    = "integrations/${aws_apigatewayv2_integration.lambda_integration.id}"
}

resource "aws_apigatewayv2_stage" "default" {
  api_id      = aws_apigatewayv2_api.hermes_api.id
  name        = "$default"
  auto_deploy = true
}

resource "aws_lambda_permission" "api_gw" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.memory_sync.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.hermes_api.execution_arn}/*/*"
}

output "api_endpoint" {
  value = aws_apigatewayv2_api.hermes_api.api_endpoint
}
