variable "ecr_repositories" {
  description = "A list of ECR repositories to create"
  type        = list(string)
}

variable "vpc_name" {
  description = "The name of the VPC"
  type        = string
}

variable "vpc_cidr_block" {
  description = "The CIDR block for the VPC"
  type        = string
}

variable "github_oidc_provider" {
  description = "GitHub OIDC provider configuration"
  type        = object({
    url            = string
    client_id_list = list(string)
    thumbprint_list = list(string)
  })
}

variable "gha_iam_role" {
  description = "GitHub Actions IAM role configuration"
  type        = object({
    name                   = string
    role_description       = string
    github_repos           = list(string)
    managed_policy_arns    = list(string)
  })
}

variable "subnet_config" {
  description = "The configuration for the subnets"
  type        = map(object({
      public_cidr_block  = string
      private_cidr_block = string
      az                 = string
  }))
}

