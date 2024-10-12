#!/bin/bash

# BASH strict mode
set -euo pipefail

# Function to check and login to AWS SSO
check_aws_sso_login() {
  if ! aws sts get-caller-identity &> /dev/null; then
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

# Function to check and login to GitHub CLI
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
    terraform init -reconfigure
    terraform apply -auto-approve
  popd
}

destroy_terraform() {
  echo "Destroying Terraform resources for test-env..."
  pushd terraform/deployments/test-env
    terraform destroy -auto-approve
  popd
}

# Function to trigger GitHub Actions workflow using gh CLI and monitor its progress
trigger_gha() {
  echo "Triggering GitHub Actions workflow..."
  workflow_run_output=$(gh workflow run "Build and Push Docker Image to ECR" --ref crawl)
  # This is a bit brittle, but it'll work for this purpose, we want the job to be registered before we query for it
  sleep 5
  run_id=$(gh run list --json databaseId --workflow="Build and Push Docker Image to ECR" --limit 1 | jq -r '.[0].databaseId')
  echo "Workflow triggered with ID: $run_id"
  echo "Monitoring workflow progress..."
  gh run watch $run_id
}

check_aws_sso_login
ACTION=${1:-}
if [ "$ACTION" == "-destroy" ]; then
  destroy_terraform
else
  check_gh_login
  deploy_terraform
  trigger_gha
fi