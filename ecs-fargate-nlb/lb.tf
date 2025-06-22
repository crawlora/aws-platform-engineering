module "sg_load_balancer" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "5.1.0"
  name    = "${local.name}-nlb-security-group"
  vpc_id  = var.vpc_id
  tags    = local.tags

  egress_with_cidr_blocks = [
    {
      from_port   = 0
      to_port     = 0
      protocol    = -1
      description = "Allow all Outgoing"
      cidr_blocks = "0.0.0.0/0"
    }
  ]

  ingress_with_cidr_blocks = [
    {
      from_port   = var.exposed_port
      to_port     = var.exposed_port
      protocol    = "tcp"
      description = "Allow HTTPS incoming"
      cidr_blocks = "0.0.0.0/0"
    },
    {
      from_port   = 9090
      to_port     = 9090
      protocol    = "tcp"
      description = "Allow HTTPS incoming"
      cidr_blocks = "0.0.0.0/0"
    }
  ]
}

resource "aws_lb" "load_balancer" {
  count               = var.enable_lb ? 1 : 0
  name                = "${local.name}-nlb"
  internal            = var.is_internal_load_balancer
  load_balancer_type  = "network"
  subnets             = var.public_subnet_ids
  enable_deletion_protection = false
  tags                = local.tags
}

resource "aws_lb_target_group" "target_group" {
  count    = var.enable_lb ? 1 : 0
  name     = "${local.name}-nlb-tg"
  port     = var.container_port
  protocol = "TCP"
  vpc_id   = var.vpc_id
  target_type = "ip"

  health_check {
    enabled             = true
    healthy_threshold   = var.healthy_threshold
    interval            = var.interval
    port                = var.exposed_port
    protocol            = "TCP"
    timeout             = var.timeout
    unhealthy_threshold = var.unhealthy_threshold
  }
}

resource "aws_lb_listener" "load_balancer" {
  count              = var.enable_lb ? 1 : 0
  load_balancer_arn  = aws_lb.load_balancer[count.index].arn
  port               = var.exposed_port
  protocol           = "TCP"
  tags               = local.tags

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.target_group[count.index].arn
  }
}

############################## Monitoring ########################################

resource "aws_sns_topic" "nlb_alerts_topic" {
  count = var.enable_lb ? 1 : 0
  name  = "${local.name}-nlb-alerts-topic"
}

resource "aws_cloudwatch_metric_alarm" "nlb_unhealthy_hosts" {
  count = var.enable_lb ? 1 : 0

  alarm_name          = "${local.name}-unhealthy-hosts"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 2
  metric_name         = "UnHealthyHostCount"
  namespace           = "AWS/NetworkELB"
  period              = 60
  statistic           = "Average"
  threshold           = 1

  dimensions = {
    LoadBalancer = aws_lb.load_balancer[count.index].arn_suffix
    TargetGroup  = aws_lb_target_group.target_group[count.index].arn_suffix
  }

  alarm_description = "Alarm when the number of unhealthy hosts is greater than or equal to the threshold."
  actions_enabled   = true
  alarm_actions     = [aws_sns_topic.nlb_alerts_topic[count.index].arn]
  tags = {
    Name = "unhealthy-hosts-alarm"
  }
}