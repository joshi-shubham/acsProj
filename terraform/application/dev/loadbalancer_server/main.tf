data "aws_ami" "latest_amazon_linux" {
  owners      = ["amazon"]
  most_recent = true
  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}

locals {
  default_tags = merge(module.globalvars.default_tags, { "env" = var.env })
  prefix       = module.globalvars.prefix
  name_prefix  = "${local.prefix}-${var.env}"
}


data "terraform_remote_state" "network" {
  backend = "s3"
  config = {
    bucket = "aafinal-project-backend"
    key    = "project/network/terraform.tfstate"
    region = "us-east-1"
  }
}


# Retrieve global variables from the Terraform module
module "globalvars" {
  source = "../../../modules/globalvars"
}

resource "aws_security_group" "alb_security_group" {
  name        = "alb-security-group"
  description = "ALB Security Group"
  vpc_id      = data.terraform_remote_state.network.outputs.vpc_id
  //vpc_id      = aws_vpc.vpc.id

  dynamic "ingress" {
    for_each = var.service_ports
    
    content {
      description = "INBOUND FROM HTTP/S"
      from_port = ingress.value
      to_port   = ingress.value
      protocol        = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }
  }
  egress {
    description = "OUTBOUND traffic to all"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
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
  //vpc_id      = aws_vpc.vpc.id

  dynamic "ingress" {
    for_each = var.service_ports
    
    content {
      description = "inbound from ALB for HTTP/S"
      from_port = ingress.value
      to_port   = ingress.value
      //cidr_blocks = ["0.0.0.0/0"]
      protocol        = "tcp"
      security_groups = [aws_security_group.alb_security_group.id]
    }
  }
  dynamic "egress" {
    for_each = var.service_ports
    
    content {
      description = "outbound to ALB for HTTP/S"
      from_port = ingress.value
      to_port   = ingress.value
      //cidr_blocks = ["0.0.0.0/0"]
      protocol        = "tcp"
      security_groups = [aws_security_group.alb_security_group.id]
    }
  }
      ingress {
      description = "SSH from bastion"
      from_port   = 22
      to_port     = 22
      protocol    = "tcp"
      security_groups = [aws_security_group.bastion_sg.id]
    }
  egress {
    description = "outbound to bastion for SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    //cidr_blocks = ["0.0.0.0/0"]
    security_groups = [aws_security_group.bastion_sg.id]
  }
  tags = merge(local.default_tags,
    {
      "Name" = "${local.name_prefix}-ASGSecurityGroup"
    }
  )
}

resource "aws_launch_template" "launch_template" {
  name          = "aws-launch-template"
  image_id      = var.ami
  instance_type = lookup(var.instance_type, var.env)
  key_name      = "final-project-staging" //added key for ec2
  metadata_options {
      http_tokens = "required"
     } 
  tag_specifications {
    resource_type = "instance"
    tags = merge(local.default_tags,
      {
        "Name" = "${local.name_prefix}-Webserver"
      }
    )
  }
  network_interfaces {
    device_index    = 0
    security_groups = [aws_security_group.asg_security_group.id]
  }
  //user_data = base64encode("${var.user_data}")

  tags = merge(local.default_tags,
    {
      "Name" = "${local.name_prefix}-ASG-Launch-Config"
    }
  )
}

resource "aws_autoscaling_group" "auto_scaling_group" {
  desired_capacity    = 3
  max_size            = 4
  min_size            = 3
  vpc_zone_identifier = data.terraform_remote_state.network.outputs.private_subnet_id
  //vpc_zone_identifier = [for i in aws_subnet.private_subnet[*] : i.id]
  target_group_arns = [aws_lb_target_group.lb_target_group.arn]
  name              = "ec2-asg"

  launch_template {
    id      = aws_launch_template.launch_template.id
    version = aws_launch_template.launch_template.latest_version
  }

}

resource "aws_lb" "alb" {
  name                       = "public-alb"
  internal                   = false
  load_balancer_type         = "application"
  security_groups            = [aws_security_group.alb_security_group.id]
  subnets                    = data.terraform_remote_state.network.outputs.public_subnet_id
  drop_invalid_header_fields = true
  //subnets            = [for i in aws_subnet.public_subnet : i.id]
  tags = merge(local.default_tags,
    {
      "Name" = "${local.name_prefix}-ALB"
    }
  )
}

resource "aws_lb_target_group" "lb_target_group" {
  name     = "lb-target-group"
  port     = 80
  protocol = "HTTP"
  vpc_id   = data.terraform_remote_state.network.outputs.vpc_id
  health_check {
    path     = "/h"
    matcher  = 200
    interval = 5
    timeout  = 2
  }

  tags = merge(local.default_tags,
    {
      "Name" = "${local.name_prefix}-ALBTargetGroup"
    }
  )
}

resource "aws_lb_listener" "alb_listener" {
  load_balancer_arn = aws_lb.alb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.lb_target_group.arn
    # redirect {
    #   port        = "80"
    #   protocol    = "HTTP"
    #   //status_code = "HTTP_301"
      
    # }
    //target_group_arn = aws_lb_target_group.lb_target_group.arn
  }
  tags = merge(local.default_tags,
    {
      "Name" = "${local.name_prefix}-ALBListener"
    }
  )
}


# Adding SSH key to Amazon EC2
resource "aws_key_pair" "web_key" {
  //key_name   = local.name_prefix
  key_name = "final-project-staging"
  //public_key = file("${local.name_prefix}.pub")
  public_key = file("final-project-staging.pub")
}


# Bastion deployment
resource "aws_instance" "bastion" {
  ami           = data.aws_ami.latest_amazon_linux.id
  instance_type = lookup(var.instance_type, var.env)
  key_name      = aws_key_pair.web_key.key_name
  //subnet_id = aws_subnet.public_subnet[0].id
  subnet_id                   = data.terraform_remote_state.network.outputs.public_subnet_id[0]
  security_groups             = [aws_security_group.bastion_sg.id]
  associate_public_ip_address = true
  root_block_device {
    encrypted = true
  }
  metadata_options {
    http_tokens = "required"
     } 
  tags = merge(local.default_tags,
    {
      "Name" = "${local.name_prefix}-bastion"
    }
  )
}

# Security Group for Bastion host
resource "aws_security_group" "bastion_sg" {
  name        = "allow_ssh, HTTP/S"
  description = "Allow SSH, HTTP/S inbound traffic"
  vpc_id      = data.terraform_remote_state.network.outputs.vpc_id


  dynamic "ingress" {
    for_each = var.service_ports
    content {
      description = "inbound from ports HTTP/S"
      from_port   = ingress.value
      to_port     = ingress.value
      cidr_blocks = ["0.0.0.0/0"]
      protocol    = "tcp"
    }
  }

    ingress {
      description = "SSH from everywhere"
      from_port   = 22
      to_port     = 22
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }

  egress {
    description = "outbound to all"
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