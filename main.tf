provider "aws" {
  region = var.region
}

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
  name = "lambda_exec_role_ASO"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role.json

  lifecycle {
    prevent_destroy       = false
    create_before_destroy = true
    ignore_changes        = [name, assume_role_policy]
  }
}

resource "aws_iam_role_policy_attachment" "lambda_basic_execution" {
  role       = aws_iam_role.lambda_exec.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_lambda_function" "my_lambda" {
  filename         = "${path.module}/modules/lambda/lambda.zip"
  function_name    = "myLambdaFunctionExecOne"
  role             = aws_iam_role.lambda_exec.arn
  handler          = "index.handler"
  runtime          = "nodejs18.x"
  source_code_hash = fileexists("${path.module}/modules/lambda/lambda.zip") ? filebase64sha256("${path.module}/modules/lambda/lambda.zip") : ""
  lifecycle {
    ignore_changes = [source_code_hash, filename]
  }
  provisioner "local-exec" {
    command    = "test -f ${path.module}/modules/lambda/lambda.zip"
    on_failure = continue
  }
}