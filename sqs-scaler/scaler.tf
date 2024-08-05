resource "aws_cloudwatch_metric_alarm" "service_sqs_usage_high" {
  alarm_name          = "${var.service_name}-sqs-usage-above-${var.max_backlog_per_task}"
  alarm_description   = "This alarm monitors ${var.service_name} sqs usage for scaling up"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = var.evaluation_periods_high
  metric_name         = "BackLogPerCapacityUnit"
  namespace           = "SQS Based Scaling Metrics"
  period              = var.evaluation_seconds_high
  statistic           = "Average"
  threshold           = var.max_backlog_per_task
  alarm_actions       = concat([aws_appautoscaling_policy.sqs_queue_consumed_scale_up.arn], var.additional_alarm_actions_scale_up)

  dimensions = {
    SQS = var.service_name
  }
}

resource "aws_appautoscaling_policy" "sqs_queue_consumed_scale_up" {
  name               = "${var.service_name}-sqs_based_scale_up-policy"
  resource_id        = "service/${var.ecs_cluster_name}/${var.service_name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"

  step_scaling_policy_configuration {
    adjustment_type         = "ChangeInCapacity"
    cooldown                = var.scale_up_cooldown_seconds
    metric_aggregation_type = "Average"

    step_adjustment {
      metric_interval_lower_bound = 0
      scaling_adjustment          = var.scale_up_number_of_tasks
    }
  }
  depends_on = [aws_appautoscaling_target.appautoscaling_target]
}

resource "aws_cloudwatch_metric_alarm" "service_sqs_usage_low" {
  alarm_name          = "${var.service_name}-sqs-usage-below-${var.max_backlog_per_task}"
  alarm_description   = "This alarm monitors ${var.service_name} sqs usage for scaling down"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = var.evaluation_periods_low
  metric_name         = "BackLogPerCapacityUnit"
  namespace           = "SQS Based Scaling Metrics"
  period              = var.evaluation_seconds_low
  statistic           = "Average"
  threshold           = var.max_backlog_per_task
  alarm_actions       = concat([aws_appautoscaling_policy.sqs_queue_consumed_scale_down.arn], var.additional_alarm_actions_scale_down)

  dimensions = {
    SQS = var.service_name
  }
}

resource "aws_appautoscaling_policy" "sqs_queue_consumed_scale_down" {
  name               = "${var.service_name}-sqs_based_scale_down-policy"
  resource_id        = "service/${var.ecs_cluster_name}/${var.service_name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"

  step_scaling_policy_configuration {
    adjustment_type         = "ChangeInCapacity"
    cooldown                = var.scale_down_cooldown_seconds
    metric_aggregation_type = "Average"

    step_adjustment {
      metric_interval_upper_bound = 0
      scaling_adjustment          = var.scale_down_number_of_tasks
    }
  }

  depends_on = [aws_appautoscaling_target.appautoscaling_target]
}

resource "aws_appautoscaling_target" "appautoscaling_target" {
  max_capacity       = var.maximum_tasks
  min_capacity       = var.minimum_tasks
  resource_id        = "service/${var.ecs_cluster_name}/${var.service_name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"
}

resource "aws_appautoscaling_scheduled_action" "ecs_scheduled_scale_in" {
  count              = var.schedule_scale_in != "" ? 1 : 0
  name               = "${var.service_name}-ecs-scheduled-scale-in"
  service_namespace  = aws_appautoscaling_target.appautoscaling_target.service_namespace
  resource_id        = aws_appautoscaling_target.appautoscaling_target.resource_id
  scalable_dimension = aws_appautoscaling_target.appautoscaling_target.scalable_dimension
  schedule           = var.schedule_scale_in
  timezone           = "Europe/Berlin"

  scalable_target_action {
    min_capacity = var.schedule_scale_in_base_tasks
  }
}

resource "aws_appautoscaling_scheduled_action" "ecs_scheduled_scale_out" {
  count              = var.schedule_scale_out != "" ? 1 : 0
  name               = "${var.service_name}-ecs-scheduled-scale-out"
  service_namespace  = aws_appautoscaling_target.appautoscaling_target.service_namespace
  resource_id        = aws_appautoscaling_target.appautoscaling_target.resource_id
  scalable_dimension = aws_appautoscaling_target.appautoscaling_target.scalable_dimension
  schedule           = var.schedule_scale_out
  timezone           = "Europe/Berlin"

  scalable_target_action {
    min_capacity = var.schedule_scale_out_base_tasks
  }
}
