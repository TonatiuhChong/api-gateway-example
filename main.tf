provider "aws" {
  region = "us-east-1"
}

resource "aws_iam_role" "api_gateway_invoke_step" {
  name = "api_gateway_invoke_step"
  assume_role_policy = data.aws_iam_policy_document.api_gateway_assume_role.json
  # Attach policy to allow StartSyncExecution on the state machine
}

data "aws_iam_policy_document" "api_gateway_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["apigateway.amazonaws.com"]
    }
  }
}

module "api_gateway" {
  source            = "./modules/api_gateway"
  state_machine_arn = module.step_function.express_state_machine_arn
  region            = var.region
  credentials_arn   = module.iam.api_gateway_invoke_role_arn
}




data "aws_iam_policy_document" "lambda_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "step_function_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["states.amazonaws.com"]
    }
  }
}

# Add the IAM module and use its outputs for role ARNs
module "iam" {
  source = "./modules/iam"
  lambda_function_arn = module.lambda.job_lambda_arn
  state_machine_arn   = module.step_function.express_state_machine_arn
}

module "lambda" {
  source                = "./modules/lambda"
  lambda_zip_path       = "./modules/lambda/lambda.zip"
  lambda_exec_role_arn  = module.iam.lambda_exec_role_arn
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

# Use the role ARN from the IAM module for policy and state machine
resource "aws_iam_role_policy" "step_function_policy" {
  name = "StepFunctionPolicy"
  role = module.iam.step_function_role_id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "lambda:InvokeFunction"
      ]
      Resource = aws_lambda_function.my_lambda.arn
    }]
  })
}

data "aws_iam_policy_document" "step_function" {
  statement {
    actions = ["lambda:InvokeFunction"]
    resources = [aws_lambda_function.my_lambda.arn]
  }
}

resource "aws_sfn_state_machine" "my_state_machine" {
  name     = "MyStateMachine"
  role_arn = module.iam.step_function_role_arn

  definition = jsonencode({
    Comment = "A simple AWS Step Function example"
    StartAt = "InvokeLambda"
    States = {
      InvokeLambda = {
        Type     = "Task"
        Resource = aws_lambda_function.my_lambda.arn
        End      = true
      }
    }
  })
}

resource "aws_api_gateway_rest_api" "api" {
  name = "step-function-api"
}

resource "aws_api_gateway_resource" "step_function_resource" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  parent_id   = aws_api_gateway_rest_api.api.root_resource_id
  path_part   = "start"
}

resource "aws_api_gateway_method" "start_method" {
  rest_api_id   = aws_api_gateway_rest_api.api.id
  resource_id   = aws_api_gateway_resource.step_function_resource.id
  http_method   = "POST"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "start_integration" {
  rest_api_id             = aws_api_gateway_rest_api.api.id
  resource_id             = aws_api_gateway_resource.step_function_resource.id
  http_method             = aws_api_gateway_method.start_method.http_method
  integration_http_method = "POST"
  type                    = "AWS"
  uri                     = "arn:aws:apigateway:${var.region}:states:action/StartExecution"

  credentials = module.iam.api_gateway_invoke_role_arn

  request_templates = {
    "application/json" = <<EOF
{
  "input": "$util.escapeJavaScript($input.body)",
  "stateMachineArn": "${aws_sfn_state_machine.my_state_machine.arn}"
}
EOF
  }
}


resource "aws_iam_role_policy" "api_gateway_policy" {
  name = "InvokeStepFunction"
  role = module.iam.api_gateway_invoke_role_id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = "states:StartExecution"
      Resource = aws_sfn_state_machine.my_state_machine.arn
    }]
  })
}

resource "aws_api_gateway_deployment" "deployment" {
  depends_on = [aws_api_gateway_integration.start_integration]
  rest_api_id = aws_api_gateway_rest_api.api.id
  stage_name  = "prod"
}
