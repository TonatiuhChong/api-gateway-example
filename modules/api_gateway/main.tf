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
  http_method   = "GET"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "start_integration" {
  rest_api_id              = aws_api_gateway_rest_api.api.id
  resource_id              = aws_api_gateway_resource.step_function_resource.id
  http_method              = aws_api_gateway_method.start_method.http_method
  integration_http_method  = "POST"
  type                     = "AWS"
  uri                      = "arn:aws:apigateway:${var.region}:states:action/StartSyncExecution"
  credentials              = var.credentials_arn

  request_templates = {
    "application/json" = <<EOF
{
  "input": "$util.escapeJavaScript($input.params().querystring)",
  "stateMachineArn": "${var.state_machine_arn}"
}
EOF
  }
}

resource "aws_api_gateway_integration_response" "start_integration_response" {
  rest_api_id  = aws_api_gateway_rest_api.api.id
  resource_id  = aws_api_gateway_resource.step_function_resource.id
  http_method  = aws_api_gateway_method.start_method.http_method
  status_code  = "200"

  response_templates = {
    "application/json" = <<EOF
#if($input.path('$.output') != "")
  #set($out = $util.parseJson($input.path('$.output')))
  $out
#else
  {
    "error": "No output from Step Function"
  }
#end
EOF
  }

  depends_on = [aws_api_gateway_integration.start_integration]
}

resource "aws_api_gateway_method_response" "start_method_response" {
  rest_api_id    = aws_api_gateway_rest_api.api.id
  resource_id    = aws_api_gateway_resource.step_function_resource.id
  http_method    = aws_api_gateway_method.start_method.http_method
  status_code    = "200"
  response_models = {
    "application/json" = "Empty"
  }
}

resource "aws_api_gateway_deployment" "deployment" {
  depends_on  = [aws_api_gateway_integration.start_integration]
  rest_api_id = aws_api_gateway_rest_api.api.id
  stage_name  = "prod"
}