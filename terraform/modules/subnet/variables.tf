variable "vpc_id" {
  type = string
  description = "The VPC ID for the subnet"
}

variable "subnet_cidr_block" {
  type = string
  description = "The CIDR block for the subnet"
}

variable "availability_zone" {
  type = string
  description = "The AZ for the subnet"
}

variable "gateway_id" {
  type = string
  description = "The gateway ID to route traffic to the internet"
}

variable "is_public" {
  type = bool
  description = "Set to true for a public subnet"
}