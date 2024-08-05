variable "config" {
  type = object({
    vpc_id              = string
    environment         = string
    name                = string
    context             = string
    security_group_ids  = list(string)
    subnet_ids          = list(string)
    certificate_arn     = string
    http_only           = optional(bool, false)
    path                = string
    port                = optional(number, 80)
    health_code         = optional(number, 200)
    healthy_threshold   = optional(number, 2)
    interval            = optional(number, 30)
    timeout             = optional(number, 15)
    unhealthy_threshold = optional(number, 3)
    tags                = map(string)
    internal            = optional(bool, false)
    target_type         = optional(string, "instance")
  })
}
