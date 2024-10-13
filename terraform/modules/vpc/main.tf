data "aws_region" "current" {}

resource "aws_vpc" "this" {
  cidr_block = var.cidr_block
  enable_dns_support = true
  enable_dns_hostnames = true

  tags = {
    Name = var.vpc_name
  }
}

resource "aws_security_group" "endpoint_allow" {
    vpc_id = aws_vpc.this.id

    egress {
      from_port = 0
      to_port   = 0
      protocol  = "-1"
      cidr_blocks = ["0.0.0.0/0"]
    }
    ingress {
      from_port = 0
      to_port   = 0
      protocol  = "-1"
      cidr_blocks = ["0.0.0.0/0"]
    }
}

resource "aws_vpc_endpoint" "this" {
  for_each = toset(var.vpc_endpoints)

  vpc_id              = aws_vpc.this.id
  service_name        = "com.amazonaws.${data.aws_region.current.name}.${each.value}"
  vpc_endpoint_type   = each.value == "s3" ? "Gateway" : "Interface"
  private_dns_enabled = each.value == "s3" ? false : true

  subnet_ids = each.value == "s3" ? null : [ for subnet in module.subnets : subnet.private_subnet_id ]

  security_group_ids = each.value == "s3" ? null : [ aws_security_group.endpoint_allow.id ]

  tags = {
    Name = "${var.vpc_name}-${each.value}-vpce"
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

