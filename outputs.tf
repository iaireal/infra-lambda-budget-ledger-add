output "function_name" {
  description = "Name of the Lambda function."
  value       = aws_lambda_function.function.function_name
}

output "function_arn" {
  description = "ARN of the Lambda function."
  value       = aws_lambda_function.function.arn
}

output "function_version" {
  description = "Release of lambda-budget-ledger-add that is deployed."
  value       = var.function_version
}

output "log_group" {
  description = "CloudWatch log group the function writes to."
  value       = aws_cloudwatch_log_group.function.name
}
