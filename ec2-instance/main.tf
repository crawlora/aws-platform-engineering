# SG Security group
locals {
  name          = "${var.config.environment}-${var.config.context}-${var.config.name}"
  vpc_id        = var.config.vpc_id
  ami_id        = var.config.instance_ami_id
  subnet_id     = var.config.subnet_id
  instance_type = var.config.instance_type
  monitoring = var.config.monitoring
  ingress_rules = var.config.create_ssh ? concat([{
    description = "Allow SSH access"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }], var.config.ingress_rules) : var.config.ingress_rules

  egress_rules = (var.config.allow_all_traffic_out || var.config.create_ssh) ? concat([{
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all traffic out"
    from_port   = 0
    to_port     = 0
  }], var.config.egress_rules) : var.config.egress_rules
  create_sg = tobool(length(local.ingress_rules) + length(local.egress_rules) > 0)

  cloud_init_cfg   = var.config.cloud_init_cfg
  cloud_init_sh    = var.config.cloud_init_sh
  cloud_init_setup = var.config.cloud_init_cfg == null && var.config.cloud_init_sh == null ? false : true

  tags = merge({
    Name = local.name
  }, var.config.tags)
  use_for_ecs = var.config.use_for_ecs
}

resource "aws_security_group" "instance_sg" {
  count       = local.create_sg ? 1 : 0
  vpc_id      = local.vpc_id
  name        = "${local.name}-sg"
  description = "${local.name}-sg"


  dynamic "egress" {
    for_each = local.egress_rules
    content {
      description = egress.value["description"]
      from_port   = egress.value["from_port"]
      to_port     = egress.value["to_port"]
      protocol    = egress.value["protocol"]
      cidr_blocks = egress.value["cidr_blocks"]
    }
  }

  dynamic "ingress" {
    for_each = local.ingress_rules
    content {
      description = ingress.value["description"]
      from_port   = ingress.value["from_port"]
      to_port     = ingress.value["to_port"]
      protocol    = ingress.value["protocol"]
      cidr_blocks = ingress.value["cidr_blocks"]
    }
  }
  tags = local.tags
}


data "template_cloudinit_config" "cloud_init" {
  count         = local.cloud_init_setup ? 1 : 0
  gzip          = true
  base64_encode = true

  part {
    filename     = "init.cfg"
    content_type = "text/cloud-config"
    #content      = data.template_file.cloud-init.rendered
    content = var.config.cloud_init_cfg
  }

  part {
    content_type = "text/x-shellscript"
    content      = var.config.cloud_init_sh
  }

}

resource "aws_instance" "instance" {

  ami           = local.ami_id
  instance_type = local.instance_type

  associate_public_ip_address = var.config.associate_public_ip_address

  subnet_id              = local.subnet_id
  vpc_security_group_ids = local.create_sg ? concat(var.config.security_group_ids, aws_security_group.instance_sg[*].id) : var.config.security_group_ids

  user_data                   = local.cloud_init_setup ? data.template_cloudinit_config.cloud_init[0].rendered : var.config.user_data_rendered
  user_data_replace_on_change = true
  key_name                    = var.config.aws_key_name
  iam_instance_profile        = var.config.iam_instance_profile_name != "" ? var.config.iam_instance_profile_name : aws_iam_instance_profile.ecs_iam_profile.name

  monitoring = local.monitoring

  # Prevent T3 Unlimited Mode (disable bursting)
  credit_specification {
    cpu_credits = var.config.cpu_credits
  }

  root_block_device {
    volume_size = var.config.volume_size
    encrypted   = true
  }
  tags = local.tags
}


resource "aws_iam_role" "ecs_instance_role" {
  name               = "ecs-instance-role-${local.name}"
  path               = "/"
  assume_role_policy = local.use_for_ecs ? data.aws_iam_policy_document.ecs_policy[0].json : data.aws_iam_policy_document.no_ecs_policy[0].json
  tags               = local.tags
}


resource "aws_iam_instance_profile" "ecs_iam_profile" {
  name = "ec2_profile-${local.name}"
  role = aws_iam_role.ecs_instance_role.name
}

data "aws_iam_policy_document" "no_ecs_policy" {
  count = local.use_for_ecs ? 0 : 1
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "ecs_policy" {
  count = local.use_for_ecs ? 1 : 0
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com", "ecs.amazonaws.com"]
    }
  }
}

resource "aws_iam_role_policy_attachment" "dev-resources-ssm-policy" {
  // Attaching SSM access
  role       = aws_iam_role.ecs_instance_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}
