output "lb_sg_id" {
  value = module.sg_load_balancer.security_group_id
}

output "task_name" {
  value = var.task_name
}

output "service_name" {
  value = aws_ecs_service.ecs_service.name
}

output "gateway_load_balancer_arn" {
  value = aws_lb_target_group.target_group.arn
}
output "gateway_load_balancer_dns" {
  value = aws_lb.load_balancer.dns_name
}

output "gateway_mgmt_load_balancer_arn" {
  value = module.gateway_mgmt_load_balancer.target_group_arn
}
output "gateway_mgmt_load_balancer_dns" {
  value = module.gateway_mgmt_load_balancer.dns_name
}

output "gateway_mgmt_load_balancer_zone_id" {
  value = module.gateway_mgmt_load_balancer.zone_id
}

output "api_oxolo_public_dns" {
  value = aws_lb.load_balancer.dns_name
}

output "api_oxolo_public_zone_id" {
  value = aws_lb.load_balancer.zone_id
}

