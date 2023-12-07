output "bastion-ip" {
  value = aws_instance.bastion.public_ip

}

output "ALB-DNS" {
  value = aws_lb.alb.dns_name
}
output name {
  value       = data.aws_iam_instance_profile.labrole.arn
}
