output "public_subnet_ids" {
  description = "List of public subnet IDs"
  value       = [ for subnet in module.subnets : subnet.public_subnet_id ]
}

output "private_subnet_ids" {
  description = "List of private subnet IDs"
  value       = [ for subnet in module.subnets : subnet.private_subnet_id ]
}

output "vpc_id" {
  description = "The ID of the VPC"
  value       = aws_vpc.this.id
}