resource "aws_security_group" "alb_security_group" {
  name        = "alb-security-group"
  description = "ALB Security Group"
  vpc_id      = data.terraform_remote_state.network.outputs.vpc_id

  dynamic "ingress" {
    for_each = var.service_ports_loadbalancer
    #tfsec:ignore:aws-ec2-no-public-ingress-sgr
    content {
      description = "INBOUND FROM HTTP/S"
      from_port   = ingress.value
      to_port     = ingress.value
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }
  }


  egress {
    description = "OUTBOUND traffic to all"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    #tfsec:ignore:aws-ec2-no-public-egress-sgr
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = merge(local.default_tags,
    {
      "Name" = "${local.name_prefix}-ALBSecurityGroup"
    }
  )
}

resource "aws_security_group" "asg_security_group" {
  name        = "asg-security-group"
  description = "ASG Security Group"
  vpc_id      = data.terraform_remote_state.network.outputs.vpc_id

  dynamic "ingress" {
    for_each = var.service_ports_webservers

    content {
      description     = "inbound from ALB for HTTP/S"
      from_port       = ingress.value
      to_port         = ingress.value
      protocol        = "tcp"
      security_groups = [aws_security_group.alb_security_group.id, aws_security_group.bastion_sg.id]
    }
  }
  egress {
    description = "OUTBOUND traffic to all"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    #tfsec:ignore:aws-ec2-no-public-egress-sgr
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = merge(local.default_tags,
    {
      "Name" = "${local.name_prefix}-ASGSecurityGroup"
    }
  )
}

# Security Group for Bastion host
resource "aws_security_group" "bastion_sg" {
  name        = "allow_ssh, HTTP/S"
  description = "Allow SSH, HTTP/S inbound traffic"
  vpc_id      = data.terraform_remote_state.network.outputs.vpc_id
  #tfsec:ignore:aws-ec2-no-public-ingress-sgr
  ingress {
    description = "SSH from everywhere"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  #tfsec:ignore:aws-ec2-no-public-egress-sgr
  egress {
    description      = "outbound to all"
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = merge(local.default_tags,
    {
      "Name" = "${local.name_prefix}-bastion-sg"
    }
  )
}
