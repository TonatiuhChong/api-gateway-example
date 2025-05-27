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