resource "aws_lambda_function" "job_lambda" {
  filename         = var.lambda_zip_path
  function_name    = "job-lambda"
  handler          = "index.handler"
  runtime          = "nodejs18.x"
  role             = var.lambda_exec_role_arn
  source_code_hash = fileexists(var.lambda_zip_path) ? filebase64sha256(var.lambda_zip_path) : null
  timeout          = 10
  memory_size      = 128

  lifecycle {
    prevent_destroy       = false
    ignore_changes        = [source_code_hash]
    create_before_destroy = true
  }

  provisioner "local-exec" {
    when    = create
    command = "test -f ${var.lambda_zip_path}"
  }
}

