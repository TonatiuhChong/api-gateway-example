resource "aws_lambda_function" "my_lambda" {
  filename         = "lambda.zip"
  function_name    = "myLambdaFunction"
  role             = var.lambda_exec_role_arn
  handler          = "index.handler"
  runtime          = "nodejs18.x"
  source_code_hash = filebase64sha256("lambda.zip")
}

output "lambda_function_arn" {
  value = aws_lambda_function.my_lambda.arn
}