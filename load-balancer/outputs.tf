output "target_group_arn" {
  value = aws_lb_target_group.target_group.arn
}

output "target_group_arn_suffix" {
  value = aws_lb_target_group.target_group.arn_suffix
}

output "dns_name" {
  value = aws_lb.load_balancer.dns_name
}

output "zone_id" {
  value = aws_lb.load_balancer.zone_id
}

output "https_target_listener_arns" {
  value = aws_lb_listener.https_target_listener[*].arn
}

output "http_target_listener_arns" {
  value = aws_lb_listener.target_listener[*].arn
}