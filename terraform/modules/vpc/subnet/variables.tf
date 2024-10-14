variable "vpc_id" {
  type        = string
  description = "The VPC ID for the subnet"
}

variable "public_cidr_block" {
  type        = string
  description = "The CIDR block for the public subnet"
}

variable "private_cidr_block" {
  type        = string
  description = "The CIDR block for the private subnet"
}

variable "availability_zone" {
  type        = string
  description = "The AZ for the subnet"
}

variable "subnet_prefix" {
  type        = string
  description = "The prefix for the subnet name"
}

variable "gateway_id" {
  type        = string
  description = "The ID of the Internet Gateway for the VPC"
}