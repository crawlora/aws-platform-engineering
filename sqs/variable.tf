variable "is_create_sqs" {
  type    = bool
  default = true
}

variable "maxRetry" {
  type        = number
  default     = 2
  description = "number of retries it will have befor moving to sqs"
}

variable "project_name" {
  type        = string
  description = "name of the project"
}



variable "app" {
  type        = string
  description = "app name of the project"
}

variable "environment" {
  default     = "prod"
  type        = string
  description = "app name of the project"
}


variable "lambda_time_out" {
  default     = 60
  type        = number
  description = "time when lambda will run out and push to sqs"
}
