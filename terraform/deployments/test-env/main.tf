data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

# This block is necessary to ensure that no "known after apply" errors are encountered during apply operations
# This allows us to create and destroy pieces of the environment without Terraform complaining
locals {
  account_id        = data.aws_caller_identity.current.account_id
  region            = data.aws_region.current.name
  fastapi_repo_name = var.ecr_repositories["fastapi"]
  lambda_repo_name  = var.ecr_repositories["lambda"]
  ecr_repo_prefix   = "${local.account_id}.dkr.ecr.${local.region}.amazonaws.com"

  fastapi_repo_url = "${local.ecr_repo_prefix}/${local.fastapi_repo_name}:latest"
  lambda_repo_url  = "${local.ecr_repo_prefix}/${local.lambda_repo_name}:latest"
}

# VPC Configuration
module "vpc" {
  source = "../../modules/vpc"

  vpc_name      = var.vpc_name
  cidr_block    = var.vpc_cidr_block
  subnet_config = var.subnet_config
  vpc_endpoints = var.vpc_endpoints
}

# ECR Configuration
module "ecr_repositories" {
  source   = "../../modules/repo"
  for_each = var.ecr_repositories

  name = each.value
}

# S3 Bucket Configuration
module "bucket" {
  source = "../../modules/bucket"

  bucket_name = var.bucket_name
}

# Github Actions Configuration
module "github_oidc_provider" {
  source = "../../modules/iam/oidc_provider"

  url             = var.github_oidc_provider.url
  client_id_list  = var.github_oidc_provider.client_id_list
  thumbprint_list = var.github_oidc_provider.thumbprint_list
}

data "aws_iam_policy_document" "ecs_lambda_allow" {
  statement {
    actions = [
      "ecs:UpdateService",
      "ecs:RegisterTaskDefinition",
      "ecs:DescribeServices",
      "ecs:ListTasks",
      "ecs:StopTask"
    ]

    resources = [
      module.ecs_cluster.cluster_arn,
      "arn:aws:ecs:${local.region}:${local.account_id}:service/*",
      "arn:aws:ecs:${local.region}:${local.account_id}:task/*",
    ]
  }

  statement {
    actions = [
      "lambda:UpdateFunctionCode",
      "lambda:PublishVersion",
      "lambda:GetFunction",
      "lambda:InvokeFunction",
      "lambda:GetFunctionConfiguration"
    ]

    resources = [
      module.lambda.lambda_arn
    ]
  }
}

module "gha_ecr_iam_role" {
  source                = "../../modules/iam/role"
  name                  = var.gha_ecr_iam_role.name
  role_description      = var.gha_ecr_iam_role.role_description
  policy_document_count = 0
  managed_policy_arns   = var.gha_ecr_iam_role.managed_policy_arns
  assume_role_actions   = ["sts:AssumeRoleWithWebIdentity"]

  principals = {
    "Federated" = [
      module.github_oidc_provider.oidc_provider_arn
    ]
  }

  assume_role_conditions = [{
    test     = "StringLike"
    variable = "token.actions.githubusercontent.com:sub"
    values   = var.gha_ecr_iam_role.github_repos
    },
    {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }
  ]
}

module "gha_ecs_lambda_iam_role" {
  source                = "../../modules/iam/role"
  name                  = var.gha_ecs_lambda_iam_role.name
  role_description      = var.gha_ecs_lambda_iam_role.role_description
  policy_document_count = 1
  assume_role_actions   = ["sts:AssumeRoleWithWebIdentity"]

  principals = {
    "Federated" = [
      module.github_oidc_provider.oidc_provider_arn
    ]
  }

  assume_role_conditions = [{
    test     = "StringLike"
    variable = "token.actions.githubusercontent.com:sub"
    values   = var.gha_ecs_lambda_iam_role.github_repos
    },
    {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }
  ]

  policy_documents = [
    data.aws_iam_policy_document.ecs_lambda_allow.json,
  ]
}

# ECS Configuration
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
          image                       = local.fastapi_repo_url
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

  depends_on = [
    module.ecr_repositories,
    module.alb
  ]
}

# Lambda Configuration
data "aws_iam_policy_document" "lambda_s3_access" {
  statement {
    actions = [
      "s3:ListBucket",
      "s3:ListBucketVersions"
    ]

    resources = [
      module.bucket.bucket_arn
    ]
  }

  statement {
    actions = [
      "s3:GetObject*",
      "s3:PutObject*"
    ]
    resources = [
      "${module.bucket.bucket_arn}/*"
    ]
  }
}

module "lambda_role" {
  source = "../../modules/iam/role"

  name                  = "${module.ecr_repositories["lambda"].repository_name}-role"
  role_description      = "IAM role for Lambda function"
  assume_role_actions   = ["sts:AssumeRole"]
  policy_document_count = 1

  principals = {
    "Service" = ["lambda.amazonaws.com"]
  }

  managed_policy_arns = [
    "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole",
    "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
  ]

  policy_documents = [
    data.aws_iam_policy_document.lambda_s3_access.json
  ]
}

module "lambda" {
  source = "../../modules/lambda"

  function_name = module.ecr_repositories["lambda"].repository_name
  role_arn      = module.lambda_role.arn
  image_uri     = local.lambda_repo_url

  subnet_ids = module.vpc.private_subnet_ids
  vpc_id     = module.vpc.vpc_id

  environment_variables = {
    "ENVIRONMENT" = "test"
  }

  depends_on = [
    module.ecr_repositories
  ]
}