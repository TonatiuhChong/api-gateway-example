data "aws_iam_policy_document" "step_function_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["states.amazonaws.com"]
    }
  }
}

resource "aws_iam_role_policy" "step_function_lambda_invoke" {
  name   = "step_function_lambda_invoke"
  role   = var.step_function_role_name
  policy = data.aws_iam_policy_document.step_function_lambda_policy.json
}

data "aws_iam_policy_document" "step_function_lambda_policy" {
  statement {
    actions   = ["lambda:InvokeFunction"]
    resources = [var.lambda_arn]
  }
}

resource "aws_sfn_state_machine" "express_state_machine" {
  name     = "express-step-function"
  role_arn = var.step_function_role_arn
  type     = "EXPRESS"

  definition = <<EOF
{
  "Comment": "Express Step Function to invoke Lambda and return output",
  "StartAt": "InvokeLambda",
  "States": {
    "InvokeLambda": {
      "Type": "Task",
      "Resource": "arn:aws:states:::lambda:invoke",
      "OutputPath": "$.Payload",
      "Parameters": {
        "FunctionName": "${var.lambda_function_arn}",
        "Payload.$": "$"
      },
      "End": true
    }
  }
}
EOF
}