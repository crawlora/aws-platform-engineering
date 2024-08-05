## Requirements

No requirements.

## Providers

| Name                                              | Version |
|---------------------------------------------------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | n/a     |

## Modules

No modules.

## Resources

| Name                                                                                                                            | Type     |
|---------------------------------------------------------------------------------------------------------------------------------|----------|
| [aws_ecs_service.service](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ecs_service)              | resource |
| [aws_ecs_task_definition.task](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ecs_task_definition) | resource |

## Inputs

| Name                                                 | Description | Type                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                         | Default | Required |
|------------------------------------------------------|-------------|------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|---------|:--------:|
| <a name="input_config"></a> [config](#input\_config) | n/a         | <pre>object({<br>    environment    = string<br>    task_name      = string // name of the task<br>    image          = string<br>    log_aws_region = string // required for log region<br>    ecs_cluster_id = string<br>    // ecs_service_role comes from ecs<br>    // ecs_service_role=string<br>    load_balancer_target_group_arn = string<br>    container_name                 = string<br>    container_port                 = string<br>    log_group                      = string<br>    command                        = list(string) //the command to execute<br><br>    desired_count = number<br>    cpu           = number<br>    memory        = number<br><br>    // role for executing the task<br>    execution_role_arn = string<br>    // role for running the task<br>    task_role_arn = string<br><br>    environment_vars = map(string)<br><br>    deployment_circuit_breaker_enable = bool<br>    deployment_circuit_breaker_rollback = bool<br><br>    instance_type_matcher = string<br>    capacity_provider_name = string<br><br> })</pre> | n/a     |   yes    |

## Outputs

No outputs.
