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
    }
    get = {
      handler     = "get.lambda_handler"
      ddb_actions = ["dynamodb:GetItem"]
    }
    list = {
      handler     = "list.lambda_handler"
      ddb_actions = ["dynamodb:Scan"]
    }
    update = {
      handler     = "update.lambda_handler"
      ddb_actions = ["dynamodb:UpdateItem"]
    }
    delete = {
      handler     = "delete.lambda_handler"
      ddb_actions = ["dynamodb:DeleteItem"]
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
