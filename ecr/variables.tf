variable "name" {
  type = string
}
variable "tags" {
  type = map(string)
}


variable "is_mutable" {
  default = true
  type = bool
  description = "tag mutability MUTABLE | IMMUTABLE @read: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ecr_repository"
}