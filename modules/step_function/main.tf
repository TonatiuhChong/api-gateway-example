resource "aws_sfn_state_machine" "my_state_machine" {
  name     = "MyStateMachine"
  role_arn = var.step_function_role_arn
  definition = jsonencode({
    Comment = "A simple AWS Step Function example",
    StartAt = "InvokeLambda",
    States = {
      InvokeLambda = {
        Type     = "Task",
        Resource = var.lambda_function_arn,
        End      = true
      }
    }
  })
}

output "state_machine_arn" {
  value = aws_sfn_state_machine.my_state_machine.arn
}