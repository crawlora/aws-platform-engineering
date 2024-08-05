module "sg_load_balancer" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "5.1.0"
  name    = "${local.name}-load-balancer-security-group"
  vpc_id  = var.vpc_id
  tags    = local.tags

  egress_with_cidr_blocks = [
    {
      from_port   = 0
      to_port     = 0
      protocol    = -1
      description = "Allow all Outgoing"
      cidr_blocks = "0.0.0.0/0"
    },
  ]

  ingress_with_cidr_blocks = [
    {
      from_port   = 80
      to_port     = 80
      protocol    = -1
      description = "Allow http incoming"
      cidr_blocks = "0.0.0.0/0"
    }
  ]
}

resource "aws_lb" "load_balancer" {
  name               = "${local.name}-api-lb"
  internal           = true
  load_balancer_type = "application"
  security_groups    = [module.sg_load_balancer.security_group_id]
  subnets            = [var.private_subnet_ids[0], var.private_subnet_ids[1]]

  enable_deletion_protection = false
  enable_http2               = true
  tags                       = local.tags
}

resource "aws_lb_listener" "load_balancer" {
  load_balancer_arn = aws_lb.load_balancer.arn
  port              = 80
  protocol          = "HTTP"
  tags              = local.tags

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.target_group.arn
  }
}

resource "aws_lb_target_group" "target_group" {
  name     = "${local.name}-tg"
  port     = var.container_port
  protocol = "HTTP"
  vpc_id   = var.vpc_id

  load_balancing_algorithm_type = "round_robin"
  slow_start                    = 30
  deregistration_delay          = 300
  target_type                   = "ip"

  health_check {
    enabled             = true
    healthy_threshold   = var.healthy_threshold
    interval            = var.interval
    matcher             = var.health_code
    path                = var.health_path
    port                = "traffic-port"
    timeout             = var.timeout
    unhealthy_threshold = var.unhealthy_threshold
  }
}

resource "aws_route53_record" "api_oxolo_internal" {
  zone_id = var.internal_zone_id
  name    = "${var.task_name}.oxolo.internal"
  type    = "A"

  alias {
    name                   = aws_lb.load_balancer.dns_name
    zone_id                = aws_lb.load_balancer.zone_id
    evaluate_target_health = true
  }
}

output "lb_sg_id" {
  value = module.sg_load_balancer.security_group_id
}
############################## Monitoring ########################################

resource "aws_sns_topic" "fargate_multi_task_topic" {
  name = "fargate-multi-task-topic"
}
resource "aws_sns_topic_subscription" "fargate_lb_subscription" {
  topic_arn = aws_sns_topic.fargate_multi_task_topic.arn
  protocol  = "email"
  endpoint  = "sprinto-prod-alerts-aaaam4d37de5is2dxufcz7h4gy@oxolo.slack.com"
}

resource "aws_cloudwatch_metric_alarm" "lb_http_4xx_errors" {
  alarm_name          = "${local.name}-http-4xx-errors-high"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 1
  metric_name         = "HTTPCode_Target_4XX_Count"
  namespace           = "AWS/ApplicationELB"
  period              = 300
  threshold           = 20

  dimensions = {
    LoadBalancer = aws_lb.load_balancer.arn_suffix
    TargetGroup  = aws_lb_target_group.target_group.arn_suffix
  }

  alarm_description         = "This metric monitors ELB 4XX errors"
  actions_enabled           = true
  alarm_actions             = [aws_sns_topic.fargate_multi_task_topic.arn]
  insufficient_data_actions = [aws_sns_topic.fargate_multi_task_topic.arn]
  tags = {
    Name = "http-4xx-error-alarm"
  }
  treat_missing_data  = "notBreaching"
  datapoints_to_alarm = 1
  extended_statistic  = "p99"
}

resource "aws_cloudwatch_metric_alarm" "lb_http_5xx_errors" {
  alarm_name          = "${local.name}-http-5xx-errors-high"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 1
  metric_name         = "HTTPCode_Target_5XX_Count"
  namespace           = "AWS/ApplicationELB"
  period              = 300
  threshold           = 10

  dimensions = {
    LoadBalancer = aws_lb.load_balancer.arn_suffix
    TargetGroup  = aws_lb_target_group.target_group.arn_suffix
  }

  alarm_description         = "This metric monitors ELB 5XX errors"
  actions_enabled           = true
  alarm_actions             = [aws_sns_topic.fargate_multi_task_topic.arn]
  insufficient_data_actions = [aws_sns_topic.fargate_multi_task_topic.arn]
  tags = {
    Name = "http-5xx-error-alarm"
  }
  treat_missing_data  = "notBreaching"
  datapoints_to_alarm = 1
  extended_statistic  = "p99"
}
resource "aws_cloudwatch_metric_alarm" "lb_latency_high" {
  alarm_name          = "${local.name}-lb-latency-high"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 2
  metric_name         = "TargetResponseTime"
  namespace           = "AWS/ApplicationELB"
  period              = 60
  threshold           = 5000 # 5 second

  dimensions = {
    TargetGroup  = aws_lb_target_group.target_group.arn_suffix
    LoadBalancer = aws_lb.load_balancer.arn_suffix
  }

  alarm_description         = "This metric monitors the average latency of the ELB"
  actions_enabled           = true
  alarm_actions             = [aws_sns_topic.fargate_multi_task_topic.arn]
  insufficient_data_actions = [aws_sns_topic.fargate_multi_task_topic.arn]
  tags = {
    Name = "high-latency-alarm"
  }
  treat_missing_data  = "notBreaching"
  datapoints_to_alarm = 1
  extended_statistic  = "p99"
}

resource "aws_cloudwatch_metric_alarm" "unhealthy_hosts" {
  alarm_name          = "${local.name}-unhealthy-hosts"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 2
  metric_name         = "UnHealthyHostCount"
  namespace           = "AWS/ApplicationELB"
  period              = 60
  statistic           = "Average"
  threshold           = 1

  dimensions = {
    LoadBalancer = aws_lb.load_balancer.arn_suffix
    TargetGroup  = aws_lb_target_group.target_group.arn_suffix
  }

  alarm_description = "Alarm when the number of unhealthy hosts is greater than or equal to the threshold."
  actions_enabled   = true
  alarm_actions     = [aws_sns_topic.fargate_multi_task_topic.arn]
  tags = {
    Name = "unhealthy-hosts-alarm"
  }
}


