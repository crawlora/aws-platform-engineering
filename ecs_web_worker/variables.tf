variable "config" {
  type = object({
    environment      = string
    context          = string
    name             = string
    ecs_cluster_name = string

    availability_zones = list(string)
    vpc_id             = string
    instance_type      = string
    subnet_ids         = list(string)

    autoscale_min     = string
    autoscale_max     = string
    autoscale_desired = string

    // for the ECS host
    aws_key_name = string
    image_id     = string
    volume_type  = string
    volume_size  = string

    // Security for the ECS host to provide the access
    security_group_ids = list(string)
    # workaround to easier upscale/downscale launch config when chaning instance
    aws_launch_configuration_suffix = string
    tags                            = map(string)
  })
}
