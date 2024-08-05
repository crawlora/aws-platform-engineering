terraform {
  backend "s3" {
    bucket  = "oxolo-tf-dev-playground"
    key     = "terraform/lambda-function-examples"
    region  = "eu-west-1"
    encrypt = true
  }
}

module "hello_world_lambda_function" {
  source = "../module"
  config = {
    environment          = "dev"
    handler              = "hello.hello_world"
    lambda_function_name = "Hello-TF"
    python_file_path     = "${path.module}/lambda/hello.py"
  }
}

module "hello_world_lambda_function_requirements" {
  source = "../module"
  config = {
    environment          = "dev"
    handler              = "hello_requirements.hello_requests"
    lambda_function_name = "Hello-NUMPY-TF"
    python_folder_path   = "${path.module}/lambda-requirements"
  }
}