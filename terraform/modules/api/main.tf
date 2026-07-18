terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    archive = {
      source  = "hashicorp/archive"
      version = "~> 2.0"
    }
  }
}

locals {
  functions = {
    create = {
      handler     = "create.lambda_handler"
      ddb_actions = ["dynamodb:PutItem"]
      route       = "POST /notes"
    }
    get = {
      handler     = "get.lambda_handler"
      ddb_actions = ["dynamodb:GetItem"]
      route       = "GET /notes/{id}"
    }
    list = {
      handler     = "list.lambda_handler"
      ddb_actions = ["dynamodb:Scan"]
      route       = "GET /notes"
    }
    update = {
      handler     = "update.lambda_handler"
      ddb_actions = ["dynamodb:UpdateItem"]
      route       = "PUT /notes/{id}"
    }
    delete = {
      handler     = "delete.lambda_handler"
      ddb_actions = ["dynamodb:DeleteItem"]
      route       = "DELETE /notes/{id}"
    }
  }
}

data "archive_file" "lambda" {
  type        = "zip"
  source_dir  = "${path.module}/../../../src/lambdas"
  output_path = "${path.module}/build/lambda.zip"
}

resource "aws_cloudwatch_log_group" "function" {
  for_each = local.functions

  name              = "/aws/lambda/${var.project}-${each.key}"
  retention_in_days = 14
}

resource "aws_iam_role" "function" {
  for_each = local.functions

  name = "${var.project}-${each.key}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      },
    ]
  })
}

resource "aws_iam_role_policy" "function" {
  for_each = local.functions

  name = "${var.project}-${each.key}"
  role = aws_iam_role.function[each.key].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = each.value.ddb_actions
        Resource = var.table_arn
      },
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogStream",
          "logs:PutLogEvents",
        ]
        Resource = aws_cloudwatch_log_group.function[each.key].arn
      },
    ]
  })
}

resource "aws_lambda_function" "function" {
  for_each = local.functions

  function_name    = "${var.project}-${each.key}"
  role             = aws_iam_role.function[each.key].arn
  handler          = each.value.handler
  runtime          = "python3.12"
  memory_size      = 128
  timeout          = 10
  filename         = data.archive_file.lambda.output_path
  source_code_hash = data.archive_file.lambda.output_base64sha256

  environment {
    variables = {
      TABLE_NAME = var.table_name
    }
  }

  depends_on = [aws_cloudwatch_log_group.function]
}

data "aws_region" "current" {}

resource "aws_apigatewayv2_api" "this" {
  name          = var.project
  protocol_type = "HTTP"

  cors_configuration {
    allow_origins = var.allowed_origins
    allow_methods = ["GET", "POST", "PUT", "DELETE", "OPTIONS"]
    allow_headers = ["content-type", "authorization"]
    max_age       = 3600
  }
}

resource "aws_apigatewayv2_authorizer" "jwt" {
  api_id           = aws_apigatewayv2_api.this.id
  authorizer_type  = "JWT"
  identity_sources = ["$request.header.Authorization"]
  name             = "${var.project}-jwt"

  jwt_configuration {
    issuer   = "https://cognito-idp.${data.aws_region.current.name}.amazonaws.com/${var.cognito_user_pool_id}"
    audience = [var.cognito_client_id]
  }
}

resource "aws_apigatewayv2_integration" "function" {
  for_each = local.functions

  api_id                 = aws_apigatewayv2_api.this.id
  integration_type       = "AWS_PROXY"
  integration_uri        = aws_lambda_function.function[each.key].invoke_arn
  payload_format_version = "2.0"
}

resource "aws_apigatewayv2_route" "function" {
  for_each = local.functions

  api_id    = aws_apigatewayv2_api.this.id
  route_key = each.value.route
  target    = "integrations/${aws_apigatewayv2_integration.function[each.key].id}"

  authorization_type = startswith(each.value.route, "GET ") ? "NONE" : "JWT"
  authorizer_id      = startswith(each.value.route, "GET ") ? null : aws_apigatewayv2_authorizer.jwt.id
}

resource "aws_apigatewayv2_stage" "default" {
  api_id      = aws_apigatewayv2_api.this.id
  name        = "$default"
  auto_deploy = true

  default_route_settings {
    throttling_burst_limit = 10
    throttling_rate_limit  = 20
  }
}

resource "aws_lambda_permission" "apigw" {
  for_each = local.functions

  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.function[each.key].function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.this.execution_arn}/*/*"
}
