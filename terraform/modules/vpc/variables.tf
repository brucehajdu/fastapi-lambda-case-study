variable "cidr_block" {
  type        = string
  description = "The CIDR range for the VPC"
}

variable "vpc_name" {
  type        = string
  description = "The name of the VPC"
}

variable "subnet_config" {
  type = map(object({
    public_cidr_block  = string
    private_cidr_block = string
    az                 = string
  }))
}

variable "vpc_endpoints" {
  type        = list(string)
  description = "A list of VPC endpoints to create"
}