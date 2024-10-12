resource "aws_subnet" "this" {
  vpc_id = var.vpc_id

  cidr_block = var.subnet_cidr_block
  map_public_ip_on_launch = var.is_public
  availability_zone = var.availability_zone
}

resource "aws_route_table" "this" {
  vpc_id = var.vpc_id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = var.gateway_id
  }
}

resource "aws_route_table_association" "this" {
  route_table_id = aws_route_table.this.id
  subnet_id = aws_subnet.this.id
}

