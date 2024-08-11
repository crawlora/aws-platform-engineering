variable "config" {
  type = object({
    name = string
    tags   = map(string)
  })
}

# variable "name" {
#   type = string
# }
# variable "tags" {
#   type = map(string)
# }
