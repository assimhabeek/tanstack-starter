output "alb_dns_name" {
  description = "The public URL of your TanStack application"
  value       = "http://${aws_lb.main.dns_name}"
}
