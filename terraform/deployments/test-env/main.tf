module "vpc" {
  source = "../../modules/vpc"

  vpc_name      = var.vpc_name
  cidr_block    = var.vpc_cidr_block
  subnet_config = var.subnet_config
  vpc_endpoints = var.vpc_endpoints
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
  source                = "../../modules/iam/role"
  name                  = var.gha_iam_role.name
  role_description      = var.gha_iam_role.role_description
  policy_document_count = 0
  managed_policy_arns   = var.gha_iam_role.managed_policy_arns
  assume_role_actions   = ["sts:AssumeRoleWithWebIdentity"]

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

module "alb" {
  source = "../../modules/alb"

  alb_name      = var.alb_name
  vpc_id        = module.vpc.vpc_id
  subnet_ids    = module.vpc.public_subnet_ids
  https_enabled = var.https_enabled
}

module "ecs_cluster" {
  source = "../../modules/ecs/"

  cluster_name = var.ecs_cluster_name

  fargate_capacity_providers = {
    FARGATE = {
      default_capacity_provider_strategy = {
        weight = 100
        base   = 1
      }
    }
  }

  services = {
    fastapi = {
      cpu    = 256
      memory = 1024

      enable_cloudwatch_logging   = true
      create_cloudwatch_log_group = true
      enable_execute_command      = true
      subnet_ids                  = module.vpc.private_subnet_ids

      load_balancer = {
        service = {
          target_group_arn = module.alb.target_group_arn
          container_name   = var.container_name
          container_port   = var.container_port
        }
      }

      security_group_rules = {
        ingress = {
          type                     = "ingress"
          from_port                = var.container_port
          to_port                  = var.container_port
          protocol                 = "-1"
          description              = "Allow traffic from the ALB"
          source_security_group_id = module.alb.security_group_id
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
        (var.container_name) = {
          create_cloudwatch_log_group = true
          enable_cloudwatch_logging   = true
          image                       = "${module.ecr_repositories["fastapi"].repository_url}:latest"
          port_mappings = [
            {
              containerPort = var.container_port
              hostPort      = var.container_port
              protocol      = "tcp"
            }
          ]

          log_configuration = {
            logDriver = "awslogs"
          }

          health_check = {
            command = ["CMD-SHELL", var.container_health_check_command]
          }
        }
      }
    }
  }
}

module "lambda_role" {
  source = "../../modules/iam/role"

  name                  = "test-lambda-role"
  role_description      = "IAM role for Lambda function"
  assume_role_actions   = ["sts:AssumeRole"]
  policy_document_count = 0

  principals = {
    "Service" = ["lambda.amazonaws.com"]
  }

  managed_policy_arns = [
    "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole",
    "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
  ]
}

module "lambda" {
  source = "../../modules/lambda"

  function_name = "test-lambda"
  role_arn      = module.lambda_role.arn
  image_uri     = "${module.ecr_repositories["fastapi-lambda"].repository_url}:latest"

  subnet_ids = module.vpc.private_subnet_ids
  vpc_id     = module.vpc.vpc_id

  environment_variables = {
    "ENVIRONMENT" = "test"
  }
}