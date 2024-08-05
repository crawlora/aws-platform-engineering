locals {
  name = "${var.config.environment}-${var.config.context}-${var.config.name}"
  tags = merge({
    Name = local.name
  }, var.config.tags)
}
resource "aws_lb_target_group" "target_group" {
  # tg = target_group
  name     = "${local.name}-tg"
  port     = var.config.port
  protocol = "HTTP"
  vpc_id   = var.config.vpc_id

  load_balancing_algorithm_type = "round_robin"
  slow_start                    = 30
  target_type                   = var.config.target_type

  health_check {
    enabled             = true
    healthy_threshold   = var.config.healthy_threshold
    interval            = var.config.interval
    matcher             = var.config.health_code
    path                = var.config.path
    port                = "traffic-port"
    timeout             = var.config.timeout
    unhealthy_threshold = var.config.unhealthy_threshold
  }
}

resource "aws_lb" "load_balancer" {
  # lb = load balancer
  name               = "${local.name}-lb"
  internal           = var.config.internal
  load_balancer_type = "application"
  security_groups    = var.config.security_group_ids
  subnets            = var.config.subnet_ids

  enable_deletion_protection = false
  enable_http2               = true
  tags                       = local.tags
}

resource "aws_lb_listener" "target_listener" {
  load_balancer_arn = aws_lb.load_balancer.arn
  port              = "80"
  protocol          = "HTTP"
  tags              = local.tags
  dynamic "default_action" {
    for_each = var.config.http_only ? [] : [1]

    content {
      type = "redirect"
      #target_group_arn = aws_lb_target_group.target_group.arn
      # Redirect to https listener
      redirect {
        port        = 443
        protocol    = "HTTPS"
        status_code = "HTTP_301"
      }
    }

  }

  dynamic "default_action" {
    for_each = var.config.http_only ? [1] : []
    content {
      type             = "forward"
      target_group_arn = aws_lb_target_group.target_group.arn

    }
  }


}

resource "aws_lb_listener" "https_target_listener" {
  count             = var.config.http_only ? 0 : 1
  load_balancer_arn = aws_lb.load_balancer.arn
  port              = "443"
  protocol          = "HTTPS"

  ssl_policy      = "ELBSecurityPolicy-2016-08"
  certificate_arn = var.config.certificate_arn
  tags            = local.tags
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.target_group.arn
  }
}

