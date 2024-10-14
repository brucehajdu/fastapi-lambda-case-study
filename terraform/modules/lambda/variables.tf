variable "role_arn" {
  description = "The ARN of the IAM role that Lambda assumes when it executes your function."
  type        = string
}

variable "image_uri" {
  description = "The URI of the container image in ECR."
  type        = string
}

variable "environment_variables" {
  description = "A map of environment variables to set in the function."
  type        = map(string)
  default     = {}
}

variable "function_name" {
  description = "The name of the Lambda function."
  type        = string
}

variable "subnet_ids" {
  description = "A list of subnet IDs associated with the Lambda function."
  type        = list(string)
}

variable "vpc_id" {
  description = "The VPC ID associated with the Lambda function."
  type        = string
}