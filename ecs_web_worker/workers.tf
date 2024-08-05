locals {
  name = "${var.config.context}-${var.config.environment}-${var.config.name}-${var.config.aws_launch_configuration_suffix}"
  // External security groups for the load balancer
  external_security_groups = var.config.security_group_ids
  ecs_cluster_name         = var.config.ecs_cluster_name
  volume_type              = var.config.volume_type
  volume_size              = var.config.volume_size
  tags = merge({
    Name = local.name
  }, var.config.tags)
}


resource "aws_iam_role" "ecs_instance_role" {
  name               = "ecs-instance-role-${local.name}"
  path               = "/"
  assume_role_policy = data.aws_iam_policy_document.ecs_instance_policy.json
  tags               = local.tags
}

resource "aws_iam_role_policy_attachment" "ecs_instance_ssm" {
  role       = aws_iam_role.ecs_instance_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

data "aws_iam_policy_document" "ecs_instance_policy" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com", "ecs.amazonaws.com"]
    }
  }
}

resource "aws_iam_role_policy_attachment" "ecs_instance_role_attachment" {
  role       = aws_iam_role.ecs_instance_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role"
}

# Attaching role to instance
resource "aws_iam_instance_profile" "ecs" {
  name = "ecs_instance_profile-${var.config.aws_launch_configuration_suffix}"
  path = "/"
  role = aws_iam_role.ecs_instance_role.id
  tags = local.tags
}

# Setting up the launch configuration for the underlaying EC2 instances
resource "aws_launch_configuration" "ecs" {
  name                        = local.name
  image_id                    = var.config.image_id
  instance_type               = var.config.instance_type
  security_groups             = local.external_security_groups
  iam_instance_profile        = aws_iam_instance_profile.ecs.name
  key_name                    = var.config.aws_key_name
  associate_public_ip_address = false
  user_data                   = <<EOF
#!/bin/bash
echo ECS_CLUSTER=${local.ecs_cluster_name} >> /etc/ecs/ecs.config
EOF

  root_block_device {
    volume_type = local.volume_type
    volume_size = local.volume_size
  }
  //lifecycle {
  //    create_before_destroy = true
  //}
}

resource "aws_autoscaling_group" "ec2_worker_launch" {
  name                 = "${local.name}-ecs-autoscaling"
  termination_policies = ["OldestLaunchConfiguration", "Default"]
  min_size             = var.config.autoscale_min
  max_size             = var.config.autoscale_max
  desired_capacity     = var.config.autoscale_desired
  health_check_type    = "EC2"
  launch_configuration = aws_launch_configuration.ecs.name
  vpc_zone_identifier  = var.config.subnet_ids

  dynamic "tag" {
    for_each = local.tags
    content {
      key                 = tag.key
      value               = tag.value
      propagate_at_launch = true
    }
  }

  lifecycle {
    create_before_destroy = true
  }
}

output "asg_name" {
  value = aws_autoscaling_group.ec2_worker_launch.name
}

output "asg_arn" {
  value = aws_autoscaling_group.ec2_worker_launch.arn

}
