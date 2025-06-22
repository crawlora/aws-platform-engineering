locals {
  resource_id        = "service/${var.ecs_cluster_name}/${aws_ecs_service.ecs_service.name}"
  service_namespace  = "ecs"
  scalable_dimension = "ecs:service:DesiredCount"
}

# Register ECS service as a scalable target
resource "aws_appautoscaling_target" "ecs" {
  max_capacity       = var.maximum_tasks
  min_capacity       = var.minimum_tasks
  resource_id        = local.resource_id
  service_namespace  = local.service_namespace
  scalable_dimension = local.scalable_dimension

  depends_on = [aws_ecs_service.ecs_service]
}


resource "aws_appautoscaling_policy" "scale_out_policy" {
  name               = "${local.name}-scale-out"
  policy_type        = "StepScaling"
  resource_id        = aws_appautoscaling_target.ecs.resource_id
  scalable_dimension = aws_appautoscaling_target.ecs.scalable_dimension
  service_namespace  = aws_appautoscaling_target.ecs.service_namespace

  step_scaling_policy_configuration {
    adjustment_type         = "ChangeInCapacity"
    cooldown                = var.scale_out_cooldown
    metric_aggregation_type = "Average"

    step_adjustment {
      scaling_adjustment = 1
      metric_interval_lower_bound = 0
    }
  }

  # depends_on = [aws_cloudwatch_metric_alarm.scale_out]
}


resource "aws_appautoscaling_policy" "scale_in_policy" {
  name               = "${local.name}-scale-in"
  policy_type        = "StepScaling"
  resource_id        = aws_appautoscaling_target.ecs.resource_id
  scalable_dimension = aws_appautoscaling_target.ecs.scalable_dimension
  service_namespace  = aws_appautoscaling_target.ecs.service_namespace

  step_scaling_policy_configuration {
    adjustment_type         = "ChangeInCapacity"
    cooldown                =  var.scale_in_cooldown
    metric_aggregation_type = "Average"

    step_adjustment {
      scaling_adjustment = -1
      metric_interval_upper_bound = 0
    }
  }

  # depends_on = [aws_cloudwatch_metric_alarm.scale_in]
}

