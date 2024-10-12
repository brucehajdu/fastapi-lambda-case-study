module "vpc" {
  source = "../../modules/vpc"

  vpc_name        = var.vpc_name
  cidr_block      = var.vpc_cidr_block
  subnet_config   = var.subnet_config
}

module "ecr_repositories" {
  source   = "../../modules/repo"
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
  name                  = var.gha_iam_role.name
  role_description      = var.gha_iam_role.role_description
  policy_document_count = 0
  managed_policy_arns   = var.gha_iam_role.managed_policy_arns
  assume_role_actions = ["sts:AssumeRoleWithWebIdentity"]

  principals = {
    "Federated" = [
      module.github_oidc_provider.oidc_provider_arn
    ]
  }

  assume_role_conditions = [{
      test     = "StringLike"
      variable = "token.actions.githubusercontent.com:sub"
      values   = var.gha_iam_role.github_repos
    },
    {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }
  ]
}