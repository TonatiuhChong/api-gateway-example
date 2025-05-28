data "aws_iam_policy_document" "lambda_assume_role" {
  statement {
    actions   = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "lambda_exec" {
  name = "lambda_exec_role_apigw_lambda"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role.json
}

resource "aws_iam_role_policy_attachment" "lambda_basic_execution" {
  role       = aws_iam_role.lambda_exec.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

data "aws_iam_policy_document" "apigw_assume_role" {
  statement {
    actions   = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["apigateway.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "apigw_lambda_invoke" {
  name = "apigw_lambda_invoke_role"
  assume_role_policy = data.aws_iam_policy_document.apigw_assume_role.json
}

resource "aws_iam_role_policy" "apigw_lambda_invoke_policy" {
  name = "apigw_lambda_invoke_policy"
  role = aws_iam_role.apigw_lambda_invoke.id
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Action = "lambda:InvokeFunction",
      Resource = var.lambda_function_arn != "" ? var.lambda_function_arn : "*"
    }]
  })
}

output "lambda_exec_role_arn" {
  value = aws_iam_role.lambda_exec.arn
}

output "apigw_lambda_invoke_role_arn" {
  value = aws_iam_role.apigw_lambda_invoke.arn
}