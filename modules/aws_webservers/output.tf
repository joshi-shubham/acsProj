output "public_ip" {
  value = aws_instance.my_amazon.public_ip
}

output "alb_public_url" {
  description = "Public URL for Application Load Balancer"
  value       = aws_lb.alb.dns_name
}