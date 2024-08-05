variable "config" {
  type = object({
    environment       = string
    context           = string
    name              = string
    retention_in_days = number
  })
}