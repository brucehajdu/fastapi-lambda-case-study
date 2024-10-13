module "vpc" {
  source = "../../modules/vpc"

  vpc_name        = var.vpc_name
  cidr_block      = var.vpc_cidr_block
  subnet_config   = var.subnet_config
  vpc_endpoints   = var.vpc_endpoints
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

module "ecs_cluster" {
  source = "../../modules/ecs/"

  cluster_name = var.ecs_cluster_name
  create_cloudwatch_log_group = false

  fargate_capacity_providers = {
    FARGATE = {
      default_capacity_provider_strategy = {
        weight = 100
        base   = 2
      }
    }
  }

  services = {
    fastapi = {
      cpu = 256
      memory = 1024

      enable_cloudwatch_logging = false
      create_cloudwatch_log_group = false
      enable_execute_command = true

      subnet_ids = module.vpc.private_subnet_ids
      security_group_rules = {
        ingress = {
          type                     = "ingress"
          from_port                = 0
          to_port                  = 0
          protocol                 = "-1"
          description              = "All Ports"
          cidr_blocks              = ["0.0.0.0/0"]
        }
        egress = {
          type        = "egress"
          from_port   = 0
          to_port     = 0
          protocol    = "-1"
          cidr_blocks = ["0.0.0.0/0"]
        }
      }

      container_definitions = {
        canary = {
          create_cloudwatch_log_group = false
          enable_cloudwatch_logging = false
          image = "${module.ecr_repositories["fastapi"].repository_url}:latest"
          port_mappings = [
            {
              containerPort = 8000
              hostPort      = 8000
              protocol      = "tcp"
            }
          ]

          health_check = {
            command = ["CMD-SHELL", "curl -f http://localhost:8000/ || exit 1"]
          }
        }
      }

    # load_balancer = {
    #   service = {
    #       target_group_arn = module.alb.target_group.arn
    #       container_name   = "fastapi"
    #       container_port   = 80
    #     }
    #   }
    }
  }
}