locals {
  resource_id        = "service/${var.ecs_cluster_name}/${aws_ecs_service.ecs_service.name}"
  service_namespace  = "ecs"
  scalable_dimension = "ecs:service:DesiredCount"
}

resource "aws_appautoscaling_target" "ecs_target" {
  max_capacity       = var.maximum_tasks
  min_capacity       = var.minimum_tasks
  resource_id        = local.resource_id
  service_namespace  = local.service_namespace
  scalable_dimension = local.scalable_dimension

  depends_on = [aws_ecs_service.ecs_service]
}

resource "aws_appautoscaling_policy" "cpu-auto-scaling" {
  count              = var.average_cpu_utilization > 0 ? 1 : 0
  name               = "${aws_ecs_service.ecs_service.name}-cpu-auto-scaling-policy"
  resource_id        = local.resource_id
  service_namespace  = local.service_namespace
  scalable_dimension = local.scalable_dimension

  policy_type = "TargetTrackingScaling"

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageCPUUtilization"
    }

    target_value       = var.average_cpu_utilization
    scale_in_cooldown  = var.scale_in_cooldown
    scale_out_cooldown = var.scale_out_cooldown
  }

  depends_on = [aws_appautoscaling_target.ecs_target]
}

resource "aws_appautoscaling_policy" "mem-auto-scaling" {
  count              = var.average_mem_utilization > 0 ? 1 : 0
  name               = "${aws_ecs_service.ecs_service.name}-mem-auto-scaling-policy"
  resource_id        = local.resource_id
  service_namespace  = local.service_namespace
  scalable_dimension = local.scalable_dimension

  policy_type = "TargetTrackingScaling"

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageMemoryUtilization"
    }

    target_value       = var.average_mem_utilization
    scale_in_cooldown  = var.scale_in_cooldown
    scale_out_cooldown = var.scale_out_cooldown
  }

  depends_on = [aws_appautoscaling_target.ecs_target]
}

resource "aws_appautoscaling_policy" "requests-auto-scaling" {
  count              = var.average_requests_per_service > 0 ? 1 : 0
  name               = "${aws_ecs_service.ecs_service.name}-requests-auto-scaling-policy"
  resource_id        = local.resource_id
  service_namespace  = local.service_namespace
  scalable_dimension = local.scalable_dimension

  policy_type = "TargetTrackingScaling"

  target_tracking_scaling_policy_configuration {
    target_value       = var.average_requests_per_service
    scale_in_cooldown  = var.scale_in_cooldown
    scale_out_cooldown = var.scale_out_cooldown

    customized_metric_specification {
      metrics {
        label = "RequestCountPerService"
        id    = "metric"

        metric_stat {
          metric {
            metric_name = "RequestCountPerTarget"
            namespace   = "AWS/ApplicationELB"


            dynamic "dimensions" {
              for_each = var.enable_lb ? [1] : []
              content {
                name  = "TargetGroup"
                value = aws_lb_target_group.target_group[0].arn_suffix
              }
            }
          }

          stat = "Sum"
        }

        return_data = true
      }
    }
  }

  depends_on = [aws_appautoscaling_target.ecs_target]
}

resource "aws_autoscaling_group" "ecs" {
  name_prefix               = "${local.name}-ecs-asg-"
  vpc_zone_identifier       = var.private_subnet_ids
  min_size                  = var.minimum_tasks
  max_size                  = var.maximum_tasks
  health_check_grace_period = 0
  health_check_type         = "EC2"
  protect_from_scale_in     = false

  launch_template {
    id      = aws_launch_template.ecs_ec2.id
    version = "$Latest"
  }

  tag {
    key                 = "Name"
    value               = "${local.name}-ecs-cluster"
    propagate_at_launch = true
  }

  tag {
    key                 = "AmazonECSManaged"
    value               = ""
    propagate_at_launch = true
  }
}
