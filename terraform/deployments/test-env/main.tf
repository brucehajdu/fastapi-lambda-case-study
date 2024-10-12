data "aws_caller_identity" "current" {}

locals {
  account_id = data.aws_caller_identity.current.account_id
}

module "ecr_repositories" {
  source = "../../modules/repo"
  for_each = toset(var.ecr_repositories)
  name = each.value
}

module "github_oidc_provider" {
  source = "../../modules/iam/oidc_provider"
  url = "https://token.actions.githubusercontent.com"
  client_id_list = ["sts.amazonaws.com"]
  thumbprint_list = ["9e99a48a9960b14926bb7f3b02e22da2b0ab7280"]
}

module "gha_iam_role" {
  source = "../../modules/iam/role"
  name = "gha-iam-role"
  role_description = "GitHub Actions - Allow build and push to ECR"
  policy_document_count = 0

  principals = {
    "Federated" = [
      module.github_oidc_provider.oidc_provider_arn
    ]
  }

  assume_role_actions = ["sts:AssumeRoleWithWebIdentity"]

  assume_role_conditions = [
    {
      test     = "StringLike"
      variable = "token.actions.githubusercontent.com:sub"
      values   = ["repo:brucehajdu/fastapi-lambda-case-study:*"]
    },
    {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }
  ]

  managed_policy_arns = [
    "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryPowerUser"
  ]
}