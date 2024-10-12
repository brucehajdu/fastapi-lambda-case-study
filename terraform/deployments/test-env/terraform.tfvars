vpc_name       = "test-vpc"
vpc_cidr_block = "10.0.0.0/20"

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
  url = "https://token.actions.githubusercontent.com"
  client_id_list = ["sts.amazonaws.com"]
  thumbprint_list = ["9e99a48a9960b14926bb7f3b02e22da2b0ab7280"]
}

gha_iam_role = {
  name = "gha-iam-role"
  role_description = "GitHub Actions - Allow build and push to ECR"

  github_repos = [
    "brucehajdu/fastapi-lambda-case-study:*"
  ]

  managed_policy_arns = [
    "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryPowerUser"
  ]
}