module "sg_load_balancer" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "5.1.0"
  name    = "${local.name}-api-load-balancer-security-group"
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
  name     = "${local.name}-api-tg"
  port     = var.container_port
  protocol = "HTTP"
  vpc_id   = var.vpc_id

  load_balancing_algorithm_type = "round_robin"
  slow_start                    = 30
  deregistration_delay          = 300
  target_type                   = "instance"

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
  name    = "${var.task_name}-api.oxolo.internal"
  type    = "A"

  alias {
    name                   = aws_lb.load_balancer.dns_name
    zone_id                = aws_lb.load_balancer.zone_id
    evaluate_target_health = true
  }
}
