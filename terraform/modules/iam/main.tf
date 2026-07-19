# 1. Mavjud OIDC Provider'ni chaqirib olamiz (YARATMAYMIZ)
data "aws_iam_openid_connect_provider" "github" {
  url = "https://token.actions.githubusercontent.com"
}

# ==========================================
# 2. PR'lar uchun PLAN Role (Read-Only)
# ==========================================
resource "aws_iam_role" "ci_plan" {
  name = "notes-ci-plan"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = "sts:AssumeRoleWithWebIdentity"
      Principal = {
        Federated = data.aws_iam_openid_connect_provider.github.arn
      }
      Condition = {
        StringEquals = {
          "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
        }
        StringLike = {
          "token.actions.githubusercontent.com:sub" = "repo:${var.github_repo}:*"
        }
      }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "ci_plan_readonly" {
  role       = aws_iam_role.ci_plan.name
  policy_arn = "arn:aws:iam::aws:policy/ReadOnlyAccess"
}

# Plan uchun State va Lock table'ga ruxsat
resource "aws_iam_role_policy" "ci_plan_state" {
  name = "ci-plan-state-access"
  role = aws_iam_role.ci_plan.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = ["s3:GetObject", "s3:ListBucket"]
        Resource = [
          "arn:aws:s3:::${var.state_bucket}",
          "arn:aws:s3:::${var.state_bucket}/*"
        ]
      },
      {
        Effect = "Allow"
        Action = ["dynamodb:GetItem", "dynamodb:PutItem", "dynamodb:DeleteItem"]
        Resource = var.lock_table_arn
      }
    ]
  })
}

# ==========================================
# 3. Main branch uchun APPLY Role (Write, Scoped)
# ==========================================
resource "aws_iam_role" "ci_apply" {
  name = "notes-ci-apply"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = "sts:AssumeRoleWithWebIdentity"
      Principal = {
        Federated = data.aws_iam_openid_connect_provider.github.arn
      }
      Condition = {
        StringEquals = {
          "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com",
          # DİQQAT: Faqat main branch'dan assume qilish mumkin!
          "token.actions.githubusercontent.com:sub" = "repo:${var.github_repo}:ref:refs/heads/main"
        }
      }
    }]
  })
}

# Apply uchun Prefix bilan cheklangan (Least Privilege) policy
resource "aws_iam_role_policy" "ci_apply_inline" {
  name = "ci-apply-permissions"
  role = aws_iam_role.ci_apply.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = ["lambda:*"]
        Resource = "arn:aws:lambda:*:*:function:notes-*"
      },
      {
        Effect = "Allow"
        Action = ["iam:*Role*", "iam:PassRole", "iam:*Policy*"]
        Resource = [
          "arn:aws:iam::*:role/notes-*",
          "arn:aws:iam::*:policy/notes-*"
        ]
      },
      {
        Effect = "Allow"
        Action = ["dynamodb:*"]
        Resource = [
          var.lock_table_arn,
          "arn:aws:dynamodb:*:*:table/notes-*"
        ]
      },
      {
        Effect = "Allow"
        Action = ["s3:*"]
        Resource = [
          "arn:aws:s3:::${var.state_bucket}",
          "arn:aws:s3:::${var.state_bucket}/*",
          "arn:aws:s3:::notes-frontend-*", # Prefix orqali frontend bucket
          "arn:aws:s3:::notes-frontend-*/*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "apigateway:*", 
          "cloudfront:CreateInvalidation", 
          "cloudfront:GetDistribution", 
          "cloudfront:UpdateDistribution"
        ]
        Resource = "*" # API GW va CF qattiq cheklovlarni yaxshi qo'llab-quvvatlamaydi
      }
    ]
  })
}

output "ci_plan_role_arn" {
  value = aws_iam_role.ci_plan.arn
}

output "ci_apply_role_arn" {
  value = aws_iam_role.ci_apply.arn
}