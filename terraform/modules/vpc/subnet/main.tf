resource "aws_subnet" "public" {
  vpc_id = var.vpc_id

  cidr_block              = var.public_cidr_block
  map_public_ip_on_launch = true
  availability_zone       = var.availability_zone
  tags = {
    Name = "${var.subnet_prefix}-public"
  }
}

resource "aws_subnet" "private" {
  vpc_id = var.vpc_id

  cidr_block              = var.private_cidr_block
  map_public_ip_on_launch = false
  availability_zone       = var.availability_zone

  tags = {
    Name = "${var.subnet_prefix}-private"
  }
}

resource "aws_route_table" "to_igw" {
  vpc_id = var.vpc_id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = var.gateway_id
  }
}

resource "aws_route_table_association" "to_igw" {
  route_table_id = aws_route_table.to_igw.id
  subnet_id      = aws_subnet.public.id
}

resource "aws_eip" "this" {}

resource "aws_nat_gateway" "this" {
  allocation_id = aws_eip.this.id
  subnet_id     = aws_subnet.public.id
}

resource "aws_route_table" "to_nat_gw" {
  vpc_id = var.vpc_id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.this.id
  }
}

resource "aws_route_table_association" "to_nat_gw" {
  route_table_id = aws_route_table.to_nat_gw.id
  subnet_id      = aws_subnet.private.id
}




