# --------------------------------------------------
# ECS Task Execution Role - Trust Policy
# --------------------------------------------------

data "aws_iam_policy_document" "ecs_task_execution_assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

# --------------------------------------------------
# ECS Task Execution Role
# --------------------------------------------------

resource "aws_iam_role" "ecs_task_execution" {
  name               = var.execution_role_name
  assume_role_policy = data.aws_iam_policy_document.ecs_task_execution_assume_role.json

  tags = {
    Name = var.execution_role_name
  }
}

# --------------------------------------------------
# ECS Task Execution Managed Policy
# --------------------------------------------------

resource "aws_iam_role_policy_attachment" "ecs_task_execution" {
  role       = aws_iam_role.ecs_task_execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# --------------------------------------------------
# GitHub Actions Terraform Permissions
# --------------------------------------------------

resource "aws_iam_role_policy" "github_actions_terraform_state" {
  name = "threatlens-terraform-state-access"
  role = "threatlens-github-actions-role"

  policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      # S3 bucket access required for Terraform backend
      {
        Sid    = "TerraformStateBucketList"
        Effect = "Allow"

        Action = [
          "s3:ListBucket"
        ]

        Resource = "arn:aws:s3:::threatlens-terraform-state-113462084471"
      },

      # Terraform state and native S3 lock file
      {
        Sid    = "TerraformStateObjects"
        Effect = "Allow"

        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject"
        ]

        Resource = [
          "arn:aws:s3:::threatlens-terraform-state-113462084471/threatlens/terraform.tfstate",
          "arn:aws:s3:::threatlens-terraform-state-113462084471/threatlens/terraform.tfstate.tflock"
        ]
      },

      # Allows Terraform to read/manage its inline policy
      {
        Sid    = "TerraformIAMPolicyManagement"
        Effect = "Allow"

        Action = [
          "iam:GetRolePolicy",
          "iam:PutRolePolicy",
          "iam:DeleteRolePolicy"
        ]

        Resource = "arn:aws:iam::113462084471:role/threatlens-github-actions-role"
      },

      # Required when Terraform refreshes CloudWatch resources
      {
        Sid    = "TerraformMonitoringTagRead"
        Effect = "Allow"

        Action = [
          "logs:ListTagsForResource",
          "cloudwatch:ListTagsForResource"
        ]

        Resource = "*"
      }
    ]
  })
}