variable "lambda_exec_role_arn" {
  description = "IAM role ARN for Lambda execution"
  type        = string
}

resource "aws_lambda_function" "my_lambda" {
  filename         = "${path.module}/get_lambda.zip"
  function_name    = "myApiGatewayLambda"
  role             = var.lambda_exec_role_arn
  handler          = "get.handler"
  runtime          = "nodejs18.x"
  source_code_hash = filebase64sha256("${path.module}/get_lambda.zip")
}

output "lambda_function_arn" {
  value = aws_lambda_function.my_lambda.arn
}

