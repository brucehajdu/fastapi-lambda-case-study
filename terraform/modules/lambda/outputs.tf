output "lambda_arn" {
  description = "The ARN of the lambda"
  value       = aws_lambda_function.this.arn
}