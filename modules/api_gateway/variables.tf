variable "state_machine_arn" {
  description = "ARN of the Step Function state machine"
  type        = string
}

variable "region" {
  description = "AWS region"
  type        = string
}

variable "credentials_arn" {
  description = "IAM role ARN for API Gateway to invoke Step Functions"
  type        = string
}

variable "lambda_function_arn" {
  description = "ARN of the Lambda function to invoke"
  type        = string

  validation {
    condition     = can(regex("^arn:aws:lambda:[^:]+:[0-9]+:function:.+", var.lambda_function_arn))
    error_message = "lambda_function_arn must be a full Lambda function ARN."
  }
}

variable "lambda_invoke_role_arn" {
  description = "IAM role ARN that API Gateway assumes to invoke Lambda"
  type        = string
}