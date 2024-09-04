variable "environment_vars" {
  type        = map(string)
  description = "A map of environment variables to be passed to the container"
}

variable "image_uri" {
  type        = string
  description = "image uri"
}


variable "project_name" {
  type        = string
  description = "name of the project"
}

variable "sqs_arns" {
  type        = list(string)
  description = "sqs arns when"
}

variable "app" {
  type        = string
  description = "app name of the project"
}


variable "environment" {
  type        = string
  description = "app name of the project"
  default     = "prod"
}

variable "lambda_memory" {
  type        = number
  default     = 512
  description = "lambda memory size"
}


variable "lambda_epermal_memory" {
  type        = number
  default     = 512
  description = "lambda ephermal memory size"
}


variable "lambda_time_out" {
  type        = number
  default     = 10 //sec
  description = "seconds of lambda is allowed to run"
}


variable "package_type" {
  type        = string
  default     = "Image"
  description = "package type image or zip @url:https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lambda_function"
}



variable "enable_xray" {
  default     = false
  type        = bool
  description = "should it use xrzy to trace the messages"
}

variable "batch_size" {
  default     = 10
  type        = number
  description = "number of messages should be processed by lambda from sqs queue"
}


variable "maximum_concurrency" {
  default     = 2
  type        = number
  description = "scaling config to maximum process messages in the queue"
}
