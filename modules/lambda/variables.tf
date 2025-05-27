variable "lambda_exec_role_arn" {
  description = "IAM role ARN for Lambda execution"
  type        = string
}

variable "lambda_zip_path" {
  description = "Path to the Lambda deployment package"
  type        = string
}