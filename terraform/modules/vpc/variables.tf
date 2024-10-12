variable "cidr_block" {
  type = string
  description = "The CIDR range for the VPC"
}

variable "subnets" {
  type = map(any)
}