variable "step_function_role_arn" {
  description = "IAM role ARN for Step Function"
  type        = string
}

variable "lambda_function_arn" {
  description = "ARN of the Lambda function"
  type        = string
}

variable "lambda_arn" {
  description = "ARN of the Lambda function"
  type        = string
}

variable "step_function_role_name" {
  description = "Name of the Step Function IAM role"
  type        = string
}