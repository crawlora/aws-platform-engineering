output "lb_sg_id" {
  value = module.sg_load_balancer.security_group_id
}


output "task_name" {
  value = var.task_name
}

output "service_name" {
  value = aws_ecs_service.ecs_service.name
}

output "target_group_name" {
  value = aws_lb_target_group.target_group.name
}

output "target_group_arn" {
  value = aws_lb_target_group.target_group.arn
}

output "target_group_arn_suffix" {
  value = aws_lb_target_group.target_group.arn_suffix
}

output "host_name" {
  value = aws_route53_record.api_oxolo_public.name
}
