output "invoke_url" {
  description = "Invoke URL for the deployed API Gateway"
  value       = aws_api_gateway_deployment.deployment.invoke_url
}
