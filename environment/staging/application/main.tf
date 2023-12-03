

#----------------------------------------------------------
# ACS730 - Week 3 - Terraform Introduction
#
# Build EC2 Instances
#
#----------------------------------------------------------

#  Define the provider
provider "aws" {
  region = "us-east-1"
}

# Data source for AMI id
data "aws_ami" "latest_amazon_linux" {
  owners      = ["amazon"]
  most_recent = true
  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}

# Use remote state to retrieve the data
# data "terraform_remote_state" "network" { // This is to use Outputs from Remote State
#   backend = "s3"
#   config = {
#     bucket = "${var.env}-acs730-week5-igeiman"      // Bucket from where to GET Terraform State
#     key    = "${var.env}-network/terraform.tfstate" // Object name in the bucket to GET Terraform State
#     region = "us-east-1"                            // Region where bucket created
#   }
# }


# Data source for availability zones in us-east-1
data "aws_availability_zones" "available" {
  state = "available"
}

resource "aws_vpc" "main" {
  cidr_block       = var.vpc_cidr
  instance_tenancy = "default"
  tags = merge(
    var.default_tags, {
      Name = "${var.prefix}-vpc"
    }
  )
}

# Add provisioning of the public subnetin the default VPC
resource "aws_subnet" "public_subnet" {
  count             = length(var.public_subnet_cidrs)
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.public_subnet_cidrs[count.index]
  availability_zone = data.aws_availability_zones.available.names[count.index]
  tags = merge(
    var.default_tags, {
      Name = "${var.prefix}-public-subnet-${count.index}"
    }
  )
}

# Add provisioning of the private subnets in the custom VPC
resource "aws_subnet" "private_subnet" {
  count             = length(var.private_subnet_cidrs)
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.private_subnet_cidrs[count.index]
  availability_zone = data.aws_availability_zones.available.names[count.index]
  tags = merge(
    var.default_tags, {
      Name = "${var.prefix}-private-subnet"
      Tier = "Private"
    }
  )
}
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id

  tags = merge(var.default_tags,
    {
      "Name" = "${var.prefix}-igw"
    }
  )
}

# Route table to route add default gateway pointing to Internet Gateway (IGW)
resource "aws_route_table" "public_route_table" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
  tags = {
    Name = "${var.prefix}-route-public-route_table"
  }
}

# Associate subnets with the custom route table
resource "aws_route_table_association" "public_route_table_association" {
  count          = length(aws_subnet.public_subnet[*].id)
  route_table_id = aws_route_table.public_route_table.id
  subnet_id      = aws_subnet.public_subnet[count.index].id
}

#Create NAT GW
resource "aws_nat_gateway" "nat-gw" {
  allocation_id = aws_eip.nat-eip.id
  subnet_id     = aws_subnet.public_subnet[0].id

  tags = {
    Name = "${var.prefix}-natgw"
  }

  # To ensure proper ordering, it is recommended to add an explicit dependency
  # on the Internet Gateway for the VPC.
  depends_on = [aws_internet_gateway.igw]
}

# Create elastic IP for NAT GW
resource "aws_eip" "nat-eip" {
  domain = vpc
  tags = {
    Name = "${var.prefix}-natgw"
  }

}

# Route table to route add default gateway pointing to NAT Gateway (NATGW)
resource "aws_route_table" "private_route_table" {
  vpc_id = aws_vpc.main.id
  tags = {
    Name = "${var.prefix}-route-private-route_table",
    Tier = "Private"
  }
}

# Add route to NAT GW if we created public subnets
resource "aws_route" "private_route" {
  route_table_id         = aws_route_table.private_route_table.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_nat_gateway.nat-gw.id
}

# Associate subnets with the custom route table
resource "aws_route_table_association" "private_route_table_association" {
  count          = length(aws_subnet.private_subnet[*].id)  
  route_table_id = aws_route_table.private_route_table.id
  subnet_id      = aws_subnet.private_subnet[count.index].id
}
# Define tags locally
locals {
  default_tags = merge(module.globalvars.default_tags, { "env" = var.env })
  prefix       = module.globalvars.prefix
  name_prefix  = "${local.prefix}-${var.env}"
}

# Retrieve global variables from the Terraform module
module "globalvars" {
  source = "../../../modules/globalvars"
}

resource "aws_security_group" "alb_security_group" {
  name        = "alb-security-group"
  description = "ALB Security Group"
  vpc_id = aws_vpc.main.id
  //vpc_id      = aws_vpc.vpc.id

  ingress {
    description = "HTTP from Internet"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

}

resource "aws_security_group" "asg_security_group" {
  name        = "asg-security-group"
  description = "ASG Security Group"
  vpc_id = aws_vpc.main.id
  //vpc_id      = aws_vpc.vpc.id

  dynamic "ingress" {
    for_each = var.service_ports
    content {
      from_port       = ingress.value
      to_port         = ingress.value
      //cidr_blocks = ["0.0.0.0/0"]
      protocol        = "tcp"
      security_groups = [aws_security_group.alb_security_group.id]
    }
  }
#   ingress {
#     description     = "HTTP from ALB"
#     from_port       = 80
#     to_port         = 80
#     protocol        = "tcp"
#     security_groups = [aws_security_group.alb_security_group.id]
#   }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_launch_template" "launch_template" {
  name          = "aws-launch-template"
  image_id      = var.ami
  instance_type = lookup(var.instance_type, var.env)

  network_interfaces {
    device_index    = 0
    security_groups = [aws_security_group.asg_security_group.id]
  }
  //user_data = base64encode("${var.user_data}")

  tags = {
    Name = "asg-ec2-template"
  }
}

resource "aws_autoscaling_group" "auto_scaling_group" {
  desired_capacity    = 3
  max_size            = 4
  min_size            = 3
  vpc_zone_identifier = [for i in aws_subnet.private_subnet[*] : i.id]
  //vpc_zone_identifier = [for i in aws_subnet.private_subnet[*] : i.id]
  target_group_arns   = [aws_lb_target_group.lb_target_group.arn]
  name = "ec2-asg"

  launch_template {
    id      = aws_launch_template.launch_template.id
    version = aws_launch_template.launch_template.latest_version
  }
}

resource "aws_lb" "alb" {
  name               = "public-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_security_group.id]
  subnets            = [for i in aws_subnet.public_subnet : i.id]
}

resource "aws_lb_target_group" "lb_target_group" {
  name     = "lb-target-group"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.vpc.id
}

resource "aws_lb_listener" "alb_listener" {
  load_balancer_arn = aws_lb.alb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.lb_target_group.arn
  }
}

# Webserver deployment
# resource "aws_instance" "my_amazon" {
#   ami                         = data.aws_ami.latest_amazon_linux.id
#   instance_type               = lookup(var.instance_type, var.env)
#   key_name                    = aws_key_pair.web_key.key_name
#   subnet_id                   = data.terraform_remote_state.network.outputs.private_subnet_ids
#   security_groups             = [aws_security_group.web_sg.id]
#   associate_public_ip_address = false
#   user_data = templatefile("${path.module}/install_httpd.sh.tpl",
#     {
#       env    = upper(var.env),
#       prefix = upper(local.prefix)
#     }
#   )

#   root_block_device {
#     encrypted = var.env == "prod" ? true : false
#   }

#   lifecycle {
#     create_before_destroy = true
#   }

#   tags = merge(local.default_tags,
#     {
#       "Name" = "${local.name_prefix}-Amazon-Linux"
#     }
#   )
# }



# Adding SSH key to Amazon EC2
resource "aws_key_pair" "web_key" {
  key_name   = local.name_prefix
  public_key = file("${local.name_prefix}.pub")
}


# Security Group
resource "aws_security_group" "web_sg" {
  name        = "allow_http_ssh"
  description = "Allow SSH inbound traffic"
  vpc_id      = data.terraform_remote_state.network.outputs.vpc_id

  dynamic "ingress" {
    for_each = var.service_ports
    content {
      from_port       = ingress.value
      to_port         = ingress.value
      //cidr_blocks = ["0.0.0.0/0"]
      security_groups = [aws_security_group.bastion_sg.id]
      protocol        = "tcp"
    }
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = merge(local.default_tags,
    {
      "Name" = "${local.name_prefix}-sg"
    }
  )
}



# Bastion deployment
resource "aws_instance" "bastion" {
  ami                         = data.aws_ami.latest_amazon_linux.id
  instance_type               = lookup(var.instance_type, var.env)
  key_name                    = aws_key_pair.web_key.key_name
  subnet_id                   = data.terraform_remote_state.network.outputs.public_subnet_ids[0]
  security_groups             = [aws_security_group.bastion_sg.id]
  associate_public_ip_address = true


  lifecycle {
    create_before_destroy = true
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
      from_port       = ingress.value
      to_port         = ingress.value
      cidr_blocks = ["0.0.0.0/0"]
      protocol        = "tcp"
    }
  }

#   ingress {
#     description = "SSH from everywhere"
#     from_port   = 22
#     to_port     = 22
#     protocol    = "tcp"
#     cidr_blocks = ["0.0.0.0/0"]
#   }

  egress {
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