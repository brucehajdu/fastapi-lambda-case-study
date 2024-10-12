resource "aws_vpc" "this" {
  cidr_block = var.cidr_block

  tags = {
    Name = var.vpc_name
  }
}

module "subnets" {
  source = "../subnet"
  for_each = var.subnet_config

  vpc_id = aws_vpc.this.id
  public_cidr_block  = each.value.public_cidr_block
  private_cidr_block = each.value.private_cidr_block
  availability_zone  = each.value.az
  gateway_id         = aws_internet_gateway.this.id
  subnet_prefix      = each.key
}

resource "aws_internet_gateway" "this" {
  vpc_id = aws_vpc.this.id
}

