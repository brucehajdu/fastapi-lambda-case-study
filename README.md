# Reorg Engineering Case Study

## Overview

This project is a case study demonstrating the deployment of a FastAPI application using AWS Lambda and ECS Fargate. The infrastructure is managed using Terraform, and the application is containerized using Docker. The project includes CI/CD pipelines to build and push Docker images to Amazon ECR and deploy the infrastructure using Terraform.

## Prerequisites

- Python 3.11
- Docker
- AWS CLI
- GitHub CLI (`gh`)
- Terraform
- GitHub Actions

## Usage

### Deploy the Environment Automatically

To deploy the environment automatically, you can use the script located in `bin/deploy.sh`. This script will build the Docker images, push them to Amazon ECR, and deploy the infrastructure using Terraform.  It will also allow you to tear the environment down when you're done.

### Detailed Build and Deploy Instructions

To build the Docker images locally, follow these steps:

**FastAPI Application**

```sh
cd api/
docker build -t fastapi:latest .
```

**Lambda Function**

```sh
cd api/
docker build -t fastapi-lambda:latest .
```

### Deploy the Terraform

To deploy the infrastructure using Terraform, follow these steps:

```sh
cd terraform/deployments/test-env
terraform init
terraform apply -auto-approve
```

This will create the necessary AWS resources, including the VPC, ECS cluster, and other required components.

## CI/CD

The project includes GitHub Actions workflows to automate the build and deployment process. The workflows are defined in the `.github/workflows` directory.

- `build_fast_api.yaml`: Triggers on pushes to the `main` branch and builds and pushes the FastAPI Docker image to Amazon ECR.
- `build_lambda.yaml`: Triggers on pushes to the `main` branch and builds and pushes the Lambda Docker image to Amazon ECR.
- `build_and_push_to_ecr.yaml`: A reusable workflow to build and push Docker images to Amazon ECR.
- `run_pytests.yaml`: Triggers on pull requests to the `main` branch and runs the test suite using Pytest.
