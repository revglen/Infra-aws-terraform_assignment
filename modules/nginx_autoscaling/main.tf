data "aws_ami" "amazon_linux" {
  most_recent = true
  
  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
  
  owners = ["amazon"]
}

resource "aws_launch_template" "nginx" {
  name_prefix   = "${var.name}-nginx-"
  image_id      = data.aws_ami.amazon_linux.id
  instance_type = var.instance_type
  key_name      = var.key_name
  
  iam_instance_profile {
    name = aws_iam_instance_profile.nginx.name
  }
  
  network_interfaces {
    associate_public_ip_address = false
    security_groups             = var.security_group_ids
    # associate_public_ip_address = true
    # security_groups             = var.security_group_ids
    #subnet_id                  = var.security_group_ids[0]
  }
  
  user_data = base64encode(templatefile("${path.module}/user_data_nginx.sh", {
    app_alb_dns_name = var.app_alb_dns_name
  }))

  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "required"
  }
  
  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "${var.name}-nginx"
    }
  }
}

resource "aws_autoscaling_group" "nginx" {
  name                = "${var.name}-nginx-asg"
  min_size            = var.min_size
  max_size            = var.max_size
  desired_capacity    = var.min_size
  vpc_zone_identifier = var.subnet_ids  
  
  launch_template {
    id      = aws_launch_template.nginx.id
    version = "$Latest"
  }
  
  target_group_arns = [var.frontend_target_group_arn]
  
  tag {
    key                 = "Name"
    value               = "${var.name}-nginx"
    propagate_at_launch = true
  }
}

resource "aws_iam_instance_profile" "nginx" {
  name = "${var.name}-nginx-instance-profile"
  role = aws_iam_role.nginx.name
}

resource "aws_iam_role" "nginx" {
  name = "${var.name}-nginx-role"
  
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "nginx_ssm" {
  role       = aws_iam_role.nginx.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# resource "aws_autoscaling_policy" "scale_out_nginx" {
#   name                   = "nginx-scale-out-policy"
#   scaling_adjustment     = 1
#   adjustment_type        = "ChangeInCapacity"
#   cooldown               = 300  # 5-minute cooldown
#   autoscaling_group_name = aws_autoscaling_group.nginx.name
#   policy_type            = "SimpleScaling"  # Explicitly set policy type
#   enabled               = true
# }

# resource "aws_cloudwatch_metric_alarm" "high_cpu_nginx" {
#   alarm_name          = "nginx-high-cpu"
#   comparison_operator = "GreaterThanOrEqualToThreshold"
#   evaluation_periods  = 1
#   metric_name         = "CPUUtilization"
#   namespace           = "AWS/EC2"
#   period              = 30  # 2 minutes
#   threshold           = 30   # Scale out at 70% CPU
#   statistic           = "Average"

#   dimensions = {
#     AutoScalingGroupName = aws_autoscaling_group.nginx.name
#   }

#   alarm_actions = [aws_autoscaling_policy.scale_out_nginx.arn]
# }

resource "aws_autoscaling_policy" "nginx_scale_out" {
  name                   = "nginx-high-requests-scale-out"
  scaling_adjustment     = 1  # Add 1 instance immediately
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 60  # Short cooldown for demo
  autoscaling_group_name = aws_autoscaling_group.nginx.name
}

# CloudWatch Alarm to trigger scale-out
resource "aws_cloudwatch_metric_alarm" "nginx_high_requests" {
  alarm_name          = "nginx-high-requests"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1  # Trigger on a single spike
  metric_name         = "RequestCount"
  namespace           = "AWS/ApplicationELB"
  period              = 60  # 1-minute evaluation
  statistic           = "Sum"
  threshold           = 200  # Scale if requests > 200 in 1 minute
  alarm_actions       = [aws_autoscaling_policy.nginx_scale_out.arn]

  dimensions = {
    LoadBalancer = var.alb_arn_suffix
  }
}

# Scale-in policy (optional, for demo cleanup)
resource "aws_autoscaling_policy" "nginx_scale_in" {
  name                   = "nginx-low-requests-scale-in"
  scaling_adjustment     = -1  # Remove 1 instance
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 300  # Longer cooldown to avoid thrashing
  autoscaling_group_name = aws_autoscaling_group.nginx.name
}

resource "aws_cloudwatch_metric_alarm" "nginx_low_requests" {
  alarm_name          = "nginx-low-requests"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = 5  # Wait for sustained low traffic
  metric_name         = "RequestCount"
  namespace           = "AWS/ApplicationELB"
  period              = 60
  statistic           = "Sum"
  threshold           = 50  # Scale in if requests < 50 for 5 minutes
  alarm_actions       = [aws_autoscaling_policy.nginx_scale_in.arn]

  dimensions = {
    LoadBalancer = var.alb_arn_suffix
  }
}