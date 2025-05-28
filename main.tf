provider "aws" {
  region = "us-east-1"
}

resource "aws_iam_role" "api_gateway_invoke_step" {
  name               = "api_gateway_invoke_step"
  assume_role_policy = data.aws_iam_policy_document.api_gateway_assume_role.json
  # Attach policy to allow StartSyncExecution on the state machine
}

data "aws_iam_policy_document" "api_gateway_assume_role" {
  statement {
    actions   = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["apigateway.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "apigw_lambda_invoke" {
  name = "apigw_lambda_invoke"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Principal = {
        Service = "apigateway.amazonaws.com"
      },
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy" "apigw_lambda_invoke_policy" {
  name = "apigw_lambda_invoke_policy"
  role = aws_iam_role.apigw_lambda_invoke.id
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = "lambda:InvokeFunction",
        Resource = [
          aws_lambda_function.my_lambda.arn,
          aws_lambda_function.my_get_lambda.arn
        ]
      }
    ]
  })
}

module "api_gateway" {
  source                = "./modules/api_gateway"
  state_machine_arn     = module.step_function.express_state_machine_arn
  region                = var.region
  credentials_arn       = module.iam.api_gateway_invoke_role_arn
  lambda_function_arn   = aws_lambda_function.my_get_lambda.arn
  lambda_invoke_role_arn = aws_iam_role.apigw_lambda_invoke.arn
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

data "aws_iam_policy_document" "step_function_assume_role" {
  statement {
    actions   = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["states.amazonaws.com"]
    }
  }
}

module "iam" {
  source              = "./modules/iam"
  lambda_function_arn = module.lambda.job_lambda_arn
  state_machine_arn   = module.step_function.express_state_machine_arn
}

module "lambda" {
  source               = "./modules/lambda"
  lambda_zip_path      = "./modules/lambda/lambda.zip"
  lambda_exec_role_arn = module.iam.lambda_exec_role_arn
}

module "step_function" {
  source                  = "./modules/step_function"
  step_function_role_arn  = module.iam.step_function_role_arn
  step_function_role_name = module.iam.step_function_role_name
  lambda_function_arn     = module.lambda.job_lambda_arn
  lambda_arn              = module.lambda.job_lambda_arn
}

resource "aws_iam_role_policy_attachment" "lambda_basic_execution" {
  role       = module.iam.lambda_exec_role_name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_lambda_function" "my_lambda" {
  filename         = "modules/lambda/lambda.zip"
  function_name    = "myLambdaFunction"
  role             = module.iam.lambda_exec_role_arn
  handler          = "index.handler"
  runtime          = "nodejs18.x"
  source_code_hash = fileexists("modules/lambda/lambda.zip") ? filebase64sha256("modules/lambda/lambda.zip") : null
}

resource "aws_lambda_function" "my_get_lambda" {
  filename         = "modules/lambda/get_lambda.zip"
  function_name    = "myGetLambdaFunction"
  role             = module.iam.lambda_exec_role_arn
  handler          = "get.handler"
  runtime          = "nodejs18.x"
  source_code_hash = fileexists("modules/lambda/get_lambda.zip") ? filebase64sha256("modules/lambda/get_lambda.zip") : null
}

resource "aws_iam_role_policy" "step_function_policy" {
  name = "StepFunctionPolicy"
  role = module.iam.step_function_role_id
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Action = [
        "lambda:InvokeFunction"
      ],
      Resource = aws_lambda_function.my_lambda.arn
    }]
  })
}

data "aws_iam_policy_document" "step_function" {
  statement {
    actions   = ["lambda:InvokeFunction"]
    resources = [aws_lambda_function.my_lambda.arn]
  }
}

resource "aws_sfn_state_machine" "my_state_machine" {
  name     = "MyStateMachine"
  role_arn = module.iam.step_function_role_arn

  definition = jsonencode({
    Comment = "A simple AWS Step Function example",
    StartAt = "InvokeLambda",
    States  = {
      InvokeLambda = {
        Type     = "Task",
        Resource = aws_lambda_function.my_lambda.arn,
        End      = true
      }
    }
  })
}

resource "aws_iam_role_policy" "api_gateway_policy" {
  name = "InvokeStepFunction"
  role = module.iam.api_gateway_invoke_role_id
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Action = "states:StartExecution",
      Resource = aws_sfn_state_machine.my_state_machine.arn
    }]
  })
}

resource "aws_lambda_permission" "apigw_invoke_lambda" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.my_get_lambda.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "arn:aws:execute-api:${var.region}:${data.aws_caller_identity.current.account_id}:*/*/GET/run-lambda"
  # If you want to allow all stages/methods, you can use: "*"
  # source_arn = "arn:aws:execute-api:${var.region}:${data.aws_caller_identity.current.account_id}:*/*/*/run-lambda"
}

data "aws_caller_identity" "current" {}
