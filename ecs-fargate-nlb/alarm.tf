

locals {
  ecs_cluster_name = element(split("/", var.ecs_cluster_id), 1) # convert arn:aws:ecs:us-east-1:123456789012:cluster/my-cluster to my-cluster

}


resource "aws_cloudwatch_metric_alarm" "scale_out" {
  count               = tobool(var.ecs_service_connect_namespace_arn != "") ? 1 : 0
  alarm_name          = "${local.name}-scale-out-alarm"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 3
  metric_name         = "NewConnectionCount"
  namespace           = "AWS/ECS"
  period              = var.cloudwatch_scale_out_period # 1 minute
  statistic           = "Sum"
  threshold           = var.average_active_connections + 1

  datapoints_to_alarm = 1

  dimensions = {
    ClusterName = local.ecs_cluster_name
    ServiceName = aws_ecs_service.ecs_service.name
    DiscoveryName = aws_ecs_service.ecs_service.name
  }

  alarm_description = "Alarm to scale out ECS service based on new connection count"
  actions_enabled = true


  alarm_actions   = [aws_appautoscaling_policy.scale_out_policy.arn]


  depends_on = [aws_appautoscaling_policy.scale_out_policy]


  
  tags = {
    Name = "${local.name}-scale-out-alarm"
  }
}




resource "aws_cloudwatch_metric_alarm" "scale_in" {
  count               = tobool(var.ecs_service_connect_namespace_arn != "") ? 1 : 0
  alarm_name          = "${local.name}-scale-in-alarm"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = 3
  metric_name         = "NewConnectionCount"
  namespace           = "AWS/ECS"
  period              = var.cloudwatch_scale_in_period # 1 minute
  statistic           = "Sum"
  threshold           = var.average_active_connections

  dimensions = {
    ClusterName = local.ecs_cluster_name
    ServiceName = aws_ecs_service.ecs_service.name
    DiscoveryName = aws_ecs_service.ecs_service.name
  }

  alarm_description = "Alarm to scale in ECS service based on new connection count"
  actions_enabled = true

  alarm_actions   = [aws_appautoscaling_policy.scale_in_policy.arn]


  depends_on = [aws_appautoscaling_policy.scale_in_policy]

  tags = {
    Name = "${local.name}-scale-in-alarm"
  }
}
