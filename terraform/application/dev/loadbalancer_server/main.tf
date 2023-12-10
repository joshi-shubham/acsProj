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
    bucket = module.globalvars.s3_dev_backend_bucket
    key    = "project/network/terraform.tfstate"
    region = "us-east-1"
  }
}

module "globalvars" {
  source = "../../../modules/globalvars"
}


resource "aws_lb" "alb" {
  name = "${local.name_prefix}-application-lb"
  #tfsec:ignore:aws-elb-alb-not-public
  internal                   = false
  load_balancer_type         = "application"
  security_groups            = [aws_security_group.alb_security_group.id]
  subnets                    = data.terraform_remote_state.network.outputs.public_subnet_id
  drop_invalid_header_fields = true
  tags = merge(local.default_tags,
    {
      "Name" = "${local.name_prefix}-ALB"
    }
  )
}

resource "aws_lb_target_group" "lb_target_group" {
  name     = "${local.name_prefix}-lb-target-group"
  port     = 80
  protocol = "HTTP"
  vpc_id   = data.terraform_remote_state.network.outputs.vpc_id

  health_check {
    path     = "/"
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



#tfsec:ignore:aws-elb-http-not-used
resource "aws_lb_listener" "alb_listener" {
  load_balancer_arn = aws_lb.alb.arn
  port              = "80"
  protocol          = "HTTP"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.lb_target_group.arn
  }
  tags = merge(local.default_tags,
    {
      "Name" = "${local.name_prefix}-ALBListener"
    }
  )
}

resource "aws_key_pair" "web_key" {
  key_name   = local.name_prefix
  public_key = file("${local.name_prefix}-key.pub")
}

resource "aws_instance" "bastion" {
  ami                         = data.aws_ami.latest_amazon_linux.id
  instance_type               = lookup(var.instance_type, var.env)
  key_name                    = aws_key_pair.web_key.key_name
  subnet_id                   = data.terraform_remote_state.network.outputs.public_subnet_id[0]
  security_groups             = [aws_security_group.bastion_sg.id]
  associate_public_ip_address = true
  root_block_device {
    encrypted = true
  }
  metadata_options {
    http_tokens = "required"
  }
  lifecycle {
    create_before_destroy = true
  }
  tags = merge(local.default_tags,
    {
      "Name" = "${local.name_prefix}-bastion"
      "role" = "bastion-${var.env}"
    }
  )
}