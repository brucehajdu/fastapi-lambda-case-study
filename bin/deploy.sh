#!/bin/bash

set -euo pipefail

check_aws_sso_login() {
  if ! aws s3 ls &> /dev/null; then
    echo "AWS SSO login required. Initiating login..."
    aws sso login
    echo "Waiting for AWS SSO login to complete..."
    for i in {1..30}; do
      if aws sts get-caller-identity &> /dev/null; then
        echo "AWS SSO login completed."
        return
      fi
      sleep 2
    done
    echo "AWS SSO login timed out."
    exit 1
  else
    echo "Already logged in to AWS SSO."
  fi
}

check_gh_login() {
  if ! gh auth status &> /dev/null; then
    echo "GitHub CLI login required. Initiating login..."
    gh auth login
    echo "Waiting for GitHub CLI login to complete..."
    for i in {1..30}; do
      if gh auth status &> /dev/null; then
        echo "GitHub CLI login completed."
        return
      fi
      sleep 2
    done
    echo "GitHub CLI login timed out."
    exit 1
  else
    echo "Already logged in to GitHub CLI."
  fi
}

deploy_terraform() {
  echo "Initializing and deploying Terraform for test-env..."
  pushd terraform/deployments/test-env
    local targets=""
    if [ "$#" -gt 0 ]; then
      echo "Found targets: $@"
      for target in "$@"; do
        targets="$targets -target=$target"
      done
    fi

    terraform init -reconfigure
    terraform apply -auto-approve $targets
  popd
}

destroy_terraform() {
  echo "Destroying Terraform resources for test-env..."
  pushd terraform/deployments/test-env
    terraform destroy -auto-approve
  popd
}

trigger_gha() {
  workflow_name=$1

  echo "Triggering GitHub Actions workflow ${workflow_name}..."
  workflow_run_output=$(gh workflow run "${workflow_name}" --ref crawl)

  # This is a bit brittle, but it'll work for this purpose, we want the job to be registered before we query for it
  sleep 5
  run_id=$(gh run list --json databaseId --workflow="${workflow_name}" --limit 1 | jq -r '.[0].databaseId')
  echo "Workflow triggered with ID: $run_id"
  echo "Monitoring workflow progress..."
  gh run watch $run_id
}

check_aws_sso_login
ACTION=${1:-}
if [ "$ACTION" == "-destroy" ]; then
  # Empty the S3 bucket and ECR repos before performing the destroy
  aws s3 rm s3://reorg-bhajdu-case-study --recursive
  aws ecr batch-delete-image --repository-name fastapi --image-ids "$(aws ecr list-images --repository-name fastapi --query 'imageIds[*]' --output json)" || echo "No images to delete"
  aws ecr batch-delete-image --repository-name fastapi-lambda --image-ids "$(aws ecr list-images --repository-name fastapi-lambda --query 'imageIds[*]' --output json)" || echo "No images to delete"
  destroy_terraform
else
  check_gh_login
  deploy_terraform "module.ecr_repositories" "module.github_oidc_provider" "module.gha_iam_role"
  trigger_gha "Build and Push FastAPI Docker Image to ECR"
  trigger_gha "Build and Push Lambda docker Image to ECR"
  deploy_terraform
fi