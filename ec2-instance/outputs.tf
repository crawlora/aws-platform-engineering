output "instance_public_ip" {
  value = aws_instance.instance.public_ip
}

output "security_groups" {
  value = aws_instance.instance.vpc_security_group_ids
}

output "instance_private_ip" {
  value       = aws_instance.instance.private_ip
  description = "The private IP address of the EC2 instance"
}

output "instance_id" {
  value       = aws_instance.instance.id
  description = "The instance ID of the EC2 instance"
}

output "iam_role" {
  value = aws_iam_role.ecs_instance_role.name
}
