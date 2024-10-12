resource "aws_vpc" "this" {
  cidr_block = var.cidr_block
}

module "public_subnets" {
  source = "../subnet"
  for_each = var.subnets

  vpc_id = aws_vpc.this.id
  subnet_cidr_block = each.value.cidr_block
  availability_zone = each.value.az
  gateway_id = aws_internet_gateway.this.id
  is_public = true
}

resource "aws_internet_gateway" "this" {
  vpc_id = aws_vpc.this.id
}

