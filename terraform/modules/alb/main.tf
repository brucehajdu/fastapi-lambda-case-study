resource "aws_alb" "this" {
  name               = var.alb_name
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.this.id]
  subnets            = var.subnet_ids
}

resource "aws_alb_listener" "http" {
  load_balancer_arn = aws_alb.this.arn
  port              = 80
  protocol          = "HTTP"

  dynamic "default_action" {
    for_each = var.https_enabled ? [1] : [0]

    content {
      type             = default_action.value == 1 ? "redirect" : "forward"
      target_group_arn = default_action.value == 1 ? null : aws_alb_target_group.this.arn

      dynamic "redirect" {
        for_each = var.https_enabled ? [1] : []

        content {
          status_code = "HTTP_301"
          protocol    = "HTTPS"
          port        = "443"
        }
      }
    }
  }
}

resource "aws_alb_listener" "https" {
  count = var.https_enabled ? 1 : 0

  load_balancer_arn = aws_alb.this.arn
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS-1-2-1-3-2021-06"
  certificate_arn   = var.certificate_arn

  default_action {
    type             = "forward"
    target_group_arn = aws_alb_target_group.this.arn
  }
}

resource "aws_alb_target_group" "this" {
  name        = var.alb_name
  port        = 80
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = var.vpc_id
}

resource "aws_security_group" "this" {
  vpc_id = var.vpc_id

  ingress {
    from_port   = var.https_enabled == true ? 443 : 80
    to_port     = var.https_enabled == true ? 443 : 80
    protocol    = "TCP"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}