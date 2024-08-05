variable "prefix" {
  description = "A prefix for all the resource"
}
variable "tag_filter" {
  description = "A tag to select the image to delete"
#  default = "AnsibleImageOriginId"
   default = "cv-service"
}
variable "delete_older_than_days" {
  description = "Delete an AMI created after this amount of days"
  default = 15
}
variable "exclusion_tag" {
  description = "Tag that if it is True block the image to be deleted"
  default = "DoNotDelete"
}
