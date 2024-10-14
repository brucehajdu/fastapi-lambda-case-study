# Reorg Engineering Case Study

## Overview

This project is a case study demonstrating the deployment of a simple FastAPI application using AWS Lambda and ECS Fargate. The infrastructure is managed using Terraform, and the application is containerized using Docker. The project includes CI/CD pipelines to build and push Docker images to Amazon ECR and deploy the infrastructure using Terraform.

## Prerequisites

- Python 3.11
- Docker
- AWS CLI
- GitHub CLI (`gh`)
- Terraform
- GitHub Actions

## Usage

### Deploy the Environment Automatically

To deploy the environment automatically, you can use the script located in `bin/deploy.sh`. 

This script will build the Docker images, push them to Amazon ECR, and deploy the infrastructure using Terraform. It will also allow you to tear the environment down when you're done.

To deploy or tear down the environment, run the following command:

```sh
# Deploy the environment
./bin/deploy.sh

# Tear down the environment
./bin/deploy.sh -destroy
```

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

### Deploy Terraform

To deploy the infrastructure using Terraform, follow these steps:

```sh
# Deploy the bootstrapping code for the remote state
cd terraform/deployments/bootstrap
terraform init
terraform apply -auto-approve

# Deploy the actual infrastructure
cd ../test-env
terraform init
terraform apply -auto-approve
```

This will create the necessary AWS resources, including the VPC, ECS cluster, FastAPI ECS service, Lambda, and other required components.

## CI/CD

The project includes GitHub Actions workflows to automate the build and deployment process. The workflows are defined in the `.github/workflows` directory.

- `build_fast_api.yaml`: Triggers on pushes to the `main` branch and builds and pushes the FastAPI Docker image to Amazon ECR.
- `build_lambda.yaml`: Triggers on pushes to the `main` branch and builds and pushes the Lambda Docker image to Amazon ECR.
- `build_and_push_to_ecr.yaml`: A reusable workflow to build and push Docker images to Amazon ECR.
- `run_pytests.yaml`: Triggers on pull requests to the `main` branch and runs the test suite using Pytest.

The workflows will be kicked off using `bin/deploy.sh` when automatically deploying the environment.

## Notes

- The FastAPI application is accessible via HTTP at the public DNS name of the ALB.
- Deploying the infrastructure will incur costs (Roughly \$2-\$3 per day). Be sure to tear down the environment when you're done.
- Tearing down the entire environment will take a while due to the ENIs attached to the lambda (AWS does not release those from the lambda for several minutes).  Terraform may time out if your timeout settings are too short.
- The ECR repositories will not be deleted when tearing down the environment **unless** the images pushed from GHA are fully deleted from the repositories first.
