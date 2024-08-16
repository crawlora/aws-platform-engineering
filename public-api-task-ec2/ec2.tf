variable "ecs_ami_id" {
  default = "ami-0a4408457f9a03be3"
  type = string
  description = "ami id of the ecs task"
}

variable "ecs_image_type" {
  default = "t2.micro"
  type = string
  description = "image type of the image"
}


resource "aws_launch_template" "ecs_ec2" {
  name_prefix            = "${local.name}-ecs-ec2-"
  image_id               = var.ecs_ami_id
  instance_type          = var.ecs_image_type
  vpc_security_group_ids = var.security_group_ids

  iam_instance_profile { arn = aws_iam_instance_profile.ecs_node.arn }
  monitoring { enabled = true }

  user_data = base64encode(<<-EOF
      #!/bin/bash
      echo ECS_CLUSTER=${var.ecs_cluster_name} >> /etc/ecs/ecs.config;
    EOF
  )
}