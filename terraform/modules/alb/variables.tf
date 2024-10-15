variable "alb_name" {
  description = "The name of the ALB"
  type        = string
}

variable "vpc_id" {
  description = "The ID of the VPC"
  type        = string
}

variable "subnet_ids" {
  description = "The IDs of the subnets"
  type        = list(string)
}

variable "https_enabled" {
  description = "Whether to enable HTTPS on the ALB"
  type        = bool
  default     = false
}

variable "certificate_arn" {
  description = "The ARN of the certificate to use for HTTPS"
  type        = string
  default     = null
}