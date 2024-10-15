# Reorg Engineering Case Study

## Overview

This project is a case study demonstrating the deployment of a simple FastAPI application using AWS Lambda and ECS 
Fargate. The infrastructure is managed using Terraform, and the application is containerized using Docker. The project 
includes CI/CD pipelines to build and deploy the ECS and Lambda containers, and deploy the infrastructure using 
Terraform.

## Prerequisites

- Python (Tested on 3.11)
- Docker
- AWS CLI with single sign-on (SSO) configured (required for deploy script, not for Terraform)
- GitHub CLI (required for deploy script to kick off GitHub Actions workflows)
- Terraform

## Usage

In order to deploy the environment using a remote state, you first need to run the `terraform/deployments/bootstrap` 
Terraform code to create the S3 bucket and DynamoDB table for remote state management. You will need to change the 
bucket name to something unique, and update `terraform/deployments/test-env/backend.tf` with the new bucket name.

If you do not want to manage this project's state remotely, change the `terraform/deployments/test-env/backend.tf` file 
to use local state.

### Deploy the Environment Automatically

To deploy the environment automatically, you can use the script located in `bin/deploy.sh`. 

This script will deploy some initial Terraform for the ECR repos, build the Docker images, push them to ECR, and deploy 
the rest of the infrastructure. It will also allow you to tear the environment down when you're done.

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

To deploy the infrastructure using Terraform, or in case of issues with the automated deployment script, follow these 
steps:

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

This will create the necessary AWS resources, including the VPC, ECS cluster, FastAPI ECS service, Lambda, and other 
required components.

## CI/CD

The project includes GitHub Actions workflows to automate the build and deployment process. The workflows are defined 
in the `.github/workflows` directory.

- `build_fast_api.yaml`: Manually triggered, builds and pushes the FastAPI Docker image to Amazon ECR.
- `build_lambda.yaml`: Manually triggered, builds and pushes the Lambda Docker image to Amazon ECR.
- `build_and_push_to_ecr.yaml`: A reusable generic workflow, used by the above jobs, to build and push Docker images to 
Amazon ECR.
- `build_and_deploy_fastapi_service.yaml`: Triggers on pushes to the `main` branch and changes to the `api/` folder, 
deploys the FastAPI ECS service.
- `build_and_deploy_lambda.yaml`: Triggers on pushes to the `main` branch and changes to the `lambda/` folder, deploys 
the Lambda function.
- `deploy_fastapi_service.yaml`: Manually triggered, deploys the FastAPI ECS service.
- `deploy_lambda.yaml`: Manually triggered, deploys the Lambda function.
- `run_pytests.yaml`: Triggers on pull requests to the `main` branch and runs the test suite using Pytest.

The `build_*` type workflows will be kicked off using `bin/deploy.sh` when automatically deploying the environment.  
This is necessary to allow the ECS and Lambda services to bootstrap properly.

## Notes

- The FastAPI application is accessible via HTTP at the public DNS name of the ALB at 
https://us-east-1.console.aws.amazon.com/ec2/home?region=us-east-1#LoadBalancers: (change the region in the URL if 
required)
- Deploying the infrastructure will incur costs (Roughly \$2-\$3 per day). Be sure to tear down the environment when 
you're done.
- Tearing down the entire environment may take a while due to the ENIs attached to the lambda (AWS does not release 
those from the lambda for several minutes).  Terraform may time out if your timeout settings are too short.
- The ECR repositories and S3 bucket will not be deleted when tearing down the environment **unless** the images pushed 
from GHA and any S3 objects are fully deleted from the repositories/bucket first.  
