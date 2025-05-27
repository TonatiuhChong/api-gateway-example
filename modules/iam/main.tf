resource "aws_iam_role" "lambda_exec" {
  name = "lambda_exec_role_ASO"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Action = "sts:AssumeRole",
      Effect = "Allow",
      Principal = {
        Service = "lambda.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_basic_execution" {
  role       = aws_iam_role.lambda_exec.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role" "step_function_role" {
  name = "step_function_role_ASO"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Action = "sts:AssumeRole",
      Effect = "Allow",
      Principal = {
        Service = "states.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_role_policy" "step_function_policy" {
  name = "StepFunctionPolicy"
  role = aws_iam_role.step_function_role.id
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Action = ["lambda:InvokeFunction"],
      Resource = var.lambda_function_arn
    }]
  })
}

resource "aws_iam_role" "api_gateway_invoke_step_function" {
  name = "APIGatewayInvokeStepFunctionRole"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Action = "sts:AssumeRole",
      Effect = "Allow",
      Principal = {
        Service = "apigateway.amazonaws.com"
      }
    }]
  })
  lifecycle {
    create_before_destroy = true
    prevent_destroy       = false
    ignore_changes        = [name]
  }
}

resource "aws_iam_role_policy" "api_gateway_policy" {
  name = "InvokeStepFunction"
  role = aws_iam_role.api_gateway_invoke_step_function.id
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Action = "states:StartExecution",
      Resource = var.state_machine_arn
    }]
  })
}

resource "aws_iam_role_policy" "api_gateway_invoke_step_start_sync" {
  name = "ApiGatewayInvokeStepStartSync"
  role = aws_iam_role.api_gateway_invoke_step_function.id
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Action = [
        "states:StartSyncExecution"
      ],
      Resource = var.state_machine_arn
    }]
  })
}

output "api_gateway_invoke_role_arn" {
  value = aws_iam_role.api_gateway_invoke_step_function.arn
}

output "lambda_exec_role_arn" {
  value = aws_iam_role.lambda_exec.arn
}

output "lambda_exec_role_name" {
  value = aws_iam_role.lambda_exec.name
}

output "step_function_role_arn" {
  value = aws_iam_role.step_function_role.arn
}

output "step_function_role_id" {
  value = aws_iam_role.step_function_role.id
}

output "api_gateway_invoke_role_id" {
  value = aws_iam_role.api_gateway_invoke_step_function.id
}

output "step_function_role_name" {
  value = aws_iam_role.step_function_role.name
}