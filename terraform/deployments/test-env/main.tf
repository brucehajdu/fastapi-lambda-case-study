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

  url             = var.github_oidc_provider.url
  client_id_list  = var.github_oidc_provider.client_id_list
  thumbprint_list = var.github_oidc_provider.thumbprint_list
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