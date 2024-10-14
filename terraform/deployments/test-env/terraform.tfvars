vpc_name         = "test-vpc"
vpc_cidr_block   = "10.0.0.0/20"
ecs_cluster_name = "test-cluster"
bucket_name      = "reorg-bhajdu-case-study"
alb_name         = "test-alb"
https_enabled    = false

container_name                 = "fastapi"
container_port                 = 8000
container_health_check_command = "curl -f http://localhost:8000/ || exit 1"

vpc_endpoints = [
  "ecr.api",
  "ecr.dkr",
  "ecs",
  "ecs-agent",
  "ecs-telemetry",
  "lambda",
  "s3"
]

subnet_config = {
  "app-use1a" = {
    public_cidr_block  = "10.0.0.0/24"
    private_cidr_block = "10.0.8.0/24"
    az                 = "us-east-1a"
  },
  "app-use1b" = {
    public_cidr_block  = "10.0.1.0/24"
    private_cidr_block = "10.0.9.0/24"
    az                 = "us-east-1b"
  },
}

ecr_repositories = [
  "fastapi",
  "fastapi-lambda"
]

github_oidc_provider = {
  url            = "https://token.actions.githubusercontent.com"
  client_id_list = ["sts.amazonaws.com"]
  thumbprint_list = [
    "9e99a48a9960b14926bb7f3b02e22da2b0ab7280",
    "74f3a68f16524f15424927704c9506f55a9316bd",
    "6938fd4d98bab03faadb97b34396831e3780aea1",
    "1c58a3a8518e8759bf075b76b750d4f2df264fcd",
  ]
}

gha_iam_role = {
  name                = "gha-iam-role"
  role_description    = "GitHub Actions - Allow build and push to ECR"
  github_repos        = ["repo:brucehajdu/fastapi-lambda-case-study:*"]
  managed_policy_arns = ["arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryPowerUser"]
}