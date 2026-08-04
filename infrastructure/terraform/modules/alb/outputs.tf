output "alb_arn" {
  description = "ARN of the Application Load Balancer."
  value       = aws_lb.main.arn
}

output "alb_dns_name" {
  description = "Public DNS name of the Application Load Balancer."
  value       = aws_lb.main.dns_name
}

output "alb_zone_id" {
  description = "Route 53 zone ID of the Application Load Balancer."
  value       = aws_lb.main.zone_id
}

output "target_group_arn" {
  description = "ARN of the backend target group."
  value       = aws_lb_target_group.backend.arn
}

output "target_group_name" {
  description = "Name of the backend target group."
  value       = aws_lb_target_group.backend.name
}

output "http_listener_arn" {
  description = "ARN of the ALB HTTP listener."
  value       = aws_lb_listener.http.arn
}