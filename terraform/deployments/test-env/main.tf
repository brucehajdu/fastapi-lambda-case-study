data "aws_caller_identity" "current" {}

locals {
  account_id = data.aws_caller_identity.current.account_id
}

module "ecr_repositories" {
  source = "../../modules/repo"
  for_each = toset(var.ecr_repositories)
  name = each.value
}

module "gha_iam_role" {
  source = "../../modules/iam/role"
  name = "gha-iam-role"
  role_description = "GitHub Actions - Allow build and push to ECR"
  policy_document_count = 0

  principals = {
      "Federated" = [
      "arn:aws:iam::${local.account_id}:oidc-provider/token.actions.githubusercontent.com"
      ]
  }

  assume_role_actions = ["sts:AssumeRoleWithWebIdentity"]

  assume_role_conditions = [
    {
      test = "StringEquals"
      variable = "token.actions.githubusercontent.com:sub"
      values = [ for repo in module.ecr_repositories : "repo:${repo.repository_name}:ref:refs/heads/main" ]
    }
  ]

  managed_policy_arns = [
    "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryPowerUser"
  ]
}