
resource "aws_launch_template" "launch_template" {
  name          = "aws-launch-template"
  image_id      = var.ami
  instance_type = lookup(var.instance_type, var.env)
  key_name      = aws_key_pair.web_key.key_name
  metadata_options {
    http_tokens = "required"
  }
  tag_specifications {
    resource_type = "instance"
    tags = merge(local.default_tags,
      {
        "Name" = "${local.name_prefix}-Webserver"
        "role" = "webserver"
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
