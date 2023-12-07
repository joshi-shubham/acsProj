data "aws_iam_instance_profile" "labrole" {
  name = "LabInstanceProfile"
}

resource "aws_launch_template" "launch_template" {
  name          = "aws-launch-template"
  image_id      = var.ami
  instance_type = lookup(var.instance_type, var.env)
  key_name      = aws_key_pair.web_key.key_name

  iam_instance_profile {
    arn = data.aws_iam_instance_profile.labrole.arn
  }
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


  tags = merge(local.default_tags,
    {
      "Name" = "${local.name_prefix}-ASG-Launch-Config"
    }
  )
}


resource "aws_autoscaling_policy" "scale_out_policy" {
  name                   = "scale_out_policy"
  scaling_adjustment     = 1
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 300
  autoscaling_group_name = aws_autoscaling_group.auto_scaling_group.name
}
resource "aws_cloudwatch_metric_alarm" "high_cpu_alarm" {
  alarm_name          = "high_cpu_alarm"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = "120"
  statistic           = "Average"
  threshold           = "10"
  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.auto_scaling_group.name
  }
  alarm_description = "metric to monitor high CPU utilization for webserver"
  alarm_actions     = [aws_autoscaling_policy.scale_out_policy.arn]
}
resource "aws_autoscaling_policy" "scale_in_policy" {
  name                   = "scale_in_policy"
  scaling_adjustment     = -1
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 300
  autoscaling_group_name = aws_autoscaling_group.auto_scaling_group.name
}
resource "aws_cloudwatch_metric_alarm" "low_cpu_alarm" {
  alarm_name          = "low_cpu_alarm"
  comparison_operator = "LessThanOrEqualToThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = "120"
  statistic           = "Average"
  threshold           = "5"
  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.auto_scaling_group.name

  }
  alarm_description = "metric to monitor low CPU utilization for webserver"
  alarm_actions     = [aws_autoscaling_policy.scale_in_policy.arn]
}
# Create a new load balancer attachment
# resource "aws_autoscaling_attachment" "example" {
#   autoscaling_group_name = aws_autoscaling_group.auto_scaling_group.id
#   elb                    = aws_lb.alb.id
# }
resource "aws_autoscaling_group" "auto_scaling_group" {
  desired_capacity    = 3
  max_size            = 4
  min_size            = 3
  vpc_zone_identifier = data.terraform_remote_state.network.outputs.private_subnet_id
  target_group_arns   = [aws_lb_target_group.lb_target_group.arn]
  name                = "ec2-asg"

  launch_template {
    id      = aws_launch_template.launch_template.id
    version = aws_launch_template.launch_template.latest_version
  }

  enabled_metrics = [
    "GroupMinSize",
    "GroupMaxSize",
    "GroupDesiredCapacity",
    "GroupInServiceInstances",
    "GroupTotalInstances"
  ]
  metrics_granularity = "1Minute"

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_attachment" "attach-ASG-TG" {
  autoscaling_group_name = aws_autoscaling_group.auto_scaling_group.name
  lb_target_group_arn = aws_lb_target_group.lb_target_group.arn
  
}