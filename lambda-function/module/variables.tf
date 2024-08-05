variable "config" {
  type = object({
    environment          = string
    lambda_function_name = string
    handler              = optional(string, "main.lambda_handler")
    python_file_path     = optional(string, null) # path to lambda #"${path.module}/lambda_function"
    python_folder_path   = optional(string, null)
    runtime              = optional(string, "python3.11")
    memory_size          = optional(number, 128)

  })
  validation {
    condition     = (var.config.python_file_path != null ? 1 : 0) + (var.config.python_folder_path != null ? 1 : 0) == 1
    error_message = "You must provide either python_file_path or python_folder_path, but not both."
  }
}