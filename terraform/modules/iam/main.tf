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
          "token.actions.githubusercontent.com:sub" = "repo:A-Kamronb3k@297892926/serverless-notes-terraform@1301875386:*"
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
        Effect   = "Allow"
        Action   = ["dynamodb:GetItem", "dynamodb:PutItem", "dynamodb:DeleteItem"]
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
          "token.actions.githubusercontent.com:sub" = "repo:A-Kamronb3k@297892926/serverless-notes-terraform@1301875386:ref:refs/heads/main"
        }
      }
    }]
  })
}

# Apply uchun to'liq Admin huquqi (Terminaldan berganimizni kodga muhrladik)
resource "aws_iam_role_policy_attachment" "ci_apply_admin" {
  role       = aws_iam_role.ci_apply.name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}

output "ci_plan_role_arn" {
  value = aws_iam_role.ci_plan.arn
}

output "ci_apply_role_arn" {
  value = aws_iam_role.ci_apply.arn
}