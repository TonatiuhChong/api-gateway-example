provider "aws" {
  region = var.region
}

module "iam" {
  source = "./modules/iam"
}

module "lambda" {
  source               = "./modules/lambda"
  lambda_exec_role_arn = module.iam.lambda_exec_role_arn
  lambda_zip_path      = "./modules/lambda/get_lambda.zip"
}

module "apigateway" {
  source                 = "./modules/apigateway"
  lambda_function_arn    = module.lambda.lambda_function_arn
  lambda_invoke_role_arn = module.iam.apigw_lambda_invoke_role_arn
  region                 = var.region
}
