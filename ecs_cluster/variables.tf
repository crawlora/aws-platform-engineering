variable "config" {
  type = object({
    environment = string
    context     = string
  })
}
