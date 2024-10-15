resource "aws_lambda_function" "this" {
  function_name = var.function_name
  role          = var.role_arn
  package_type  = "Image"
  image_uri     = var.image_uri

  environment {
    variables = var.environment_variables
  }

  vpc_config {
    security_group_ids = [aws_security_group.this.id]
    subnet_ids         = var.subnet_ids
  }
}

resource "aws_security_group" "this" {
  name        = "lambda-sg"
  description = "Security group for Lambda function"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_cloudwatch_event_rule" "lambda_schedule" {
  name                = "lambda-schedule"
  description         = "Trigger Lambda function every hour"
  schedule_expression = "rate(1 hour)"
}

resource "aws_cloudwatch_event_target" "lambda_target" {
  rule      = aws_cloudwatch_event_rule.lambda_schedule.name
  target_id = "lambda"
  arn       = aws_lambda_function.this.arn
}

resource "aws_lambda_permission" "allow_cloudwatch" {
  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.this.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.lambda_schedule.arn
}
