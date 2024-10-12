output "public_subnet_id" {
    value = aws_subnet.public.id
}

output "private_subnet_id" {
    value = aws_subnet.private.id
}

output "nat_gateway_id" {
    value = aws_nat_gateway.this.id
}

output "igw_route_table_id" {
    value = aws_route_table.to_igw.id
}

output "nat_route_table_id" {
    value = aws_route_table.to_nat_gw.id
}
