variable "config" {
  type = object({
    // Custom variable to specify the environment.
    environment = string
    name        = string
    context     = string
    // VPC/Networking properties
    vpc_id                      = string
    subnet_id                   = string
    associate_public_ip_address = optional(bool, true)
    // Instance setting
    instance_ami_id       = string
    instance_type         = string
   // instance_id           = string
    aws_key_name          = optional(string, null)
    security_group_ids    = optional(list(string), [])
    create_ssh            = optional(bool, false)
    allow_all_traffic_out = optional(bool, false)

    monitoring = optional(bool, false)

    cpu_credits = optional(string, "standard")

    egress_rules = optional(list(object({
      description = string
      from_port   = number
      to_port     = number
      protocol    = string
      cidr_blocks = list(string)
    })), [])

    ingress_rules = optional(list(object({
      description = string
      from_port   = number
      to_port     = number
      protocol    = optional(string, "-1")
      cidr_blocks = optional(list(string), ["0.0.0.0/0"])
    })), [])

    // Define if it used as ECS instances
    use_for_ecs               = optional(bool, false)
    iam_instance_profile_name = optional(string, "")

    cloud_init_cfg     = optional(string, null)
    cloud_init_sh      = optional(string, null)
    volume_size        = optional(number, 20)
    user_data_rendered = optional(string, null)
    tags               = map(string)
  })
}
