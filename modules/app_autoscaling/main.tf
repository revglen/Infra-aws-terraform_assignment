data "aws_ami" "amazon_linux" {
  most_recent = true
  
  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
  
  owners = ["amazon"]
}

resource "aws_key_pair" "deployer" {
  key_name   = "${var.name}-deployer-key"
  public_key = file("~/.ssh/aws_key.pub")
}

resource "aws_launch_template" "app" {
  name_prefix   = "${var.name}-app-"
  image_id      = data.aws_ami.amazon_linux.id
  instance_type = var.instance_type
  key_name      = aws_key_pair.deployer.key_name
  
  iam_instance_profile {
    name = aws_iam_instance_profile.app.name
  }
  
  network_interfaces {
    associate_public_ip_address = false
    security_groups             = var.security_group_ids
    # associate_public_ip_address = true
    # security_groups             = var.security_group_ids
    #subnet_id                  = var.security_group_ids[0]
  }

  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "required"
  }
  
  user_data = base64encode(templatefile("${path.module}/user_data_app.sh", {
    db_endpoint = var.db_endpoint
    db_username = var.db_username
    db_password = var.db_password
    db_name     = var.db_name
  }))
  
  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "${var.name}-app"
    }
  }
}

resource "aws_autoscaling_group" "app" {
  name                = "${var.name}-app-asg"
  min_size            = var.min_size
  max_size            = var.max_size
  desired_capacity    = var.desired_capacity
  vpc_zone_identifier = var.subnet_ids
  
  launch_template {
    id      = aws_launch_template.app.id
    version = "$Latest"
  }
  
  target_group_arns = [aws_lb_target_group.app.arn]
  
  tag {
    key                 = "Name"
    value               = "${var.name}-app"
    propagate_at_launch = true
  }
}

resource "aws_lb" "app" {
  name               = "${var.name}-app-alb"
  internal           = true
  load_balancer_type = "application"
  security_groups    = var.security_group_ids
  subnets            = var.subnet_ids
  
  enable_deletion_protection = false
  
  tags = {
    Name = "${var.name}-app-alb"
  }
}

resource "aws_lb_target_group" "app" {
  name     = "${var.name}-app-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = var.vpc_id
  
  health_check {
    path                = "/health"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
    matcher             = "200"
  }
}

resource "aws_lb_listener" "app" {
  
  load_balancer_arn = aws_lb.app.arn
  port              = "80"
  protocol          = "HTTP"
  
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app.arn
  }
}

resource "aws_iam_instance_profile" "app" {
  name = "${var.name}-app-instance-profile"
  role = aws_iam_role.app.name
}

resource "aws_iam_role" "app" {
  name = "${var.name}-app-role"
  
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

resource "aws_iam_role_policy_attachment" "app_ssm" {
  role       = aws_iam_role.app.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# resource "aws_autoscaling_policy" "scale_out_app" {
#   name                   = "fastapi-scale-out-policy"
#   scaling_adjustment     = 1
#   adjustment_type        = "ChangeInCapacity"
#   cooldown               = 300  # 5-minute cooldown
#   autoscaling_group_name = aws_autoscaling_group.app.name
#   policy_type            = "SimpleScaling"  # Explicitly set policy type
#   enabled               = true
# }

# resource "aws_cloudwatch_metric_alarm" "high_cpu_app" {
#   alarm_name          = "fastapi-high-cpu"
#   comparison_operator = "GreaterThanOrEqualToThreshold"
#   evaluation_periods  = 1
#   metric_name         = "CPUUtilization"
#   namespace           = "AWS/EC2"
#   period              = 30
#   threshold           = 30
#   statistic           = "Average"

#   dimensions = {
#     AutoScalingGroupName = aws_autoscaling_group.app.name
#   }

#   alarm_actions = [aws_autoscaling_policy.scale_out_app.arn]
# }

resource "aws_autoscaling_policy" "scale_out_app" {
  name                   = "fastapi-request-scale-out-policy"
  scaling_adjustment     = 1
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 100  # 5-minute cooldown
  autoscaling_group_name = aws_autoscaling_group.app.name
  policy_type            = "SimpleScaling"
}

resource "aws_cloudwatch_metric_alarm" "high_requests_app" {
  alarm_name          = "fastapi-high-requests-per-target"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 1
  threshold           = 200  # Scale when >200 requests per target
  alarm_description   = "Triggers when ALB requests per target exceed threshold"

  # CORRECT METRIC CONFIGURATION
  metric_name         = "RequestCountPerTarget"
  namespace           = "AWS/ApplicationELB"
  period              = 60
  statistic           = "Average"

  dimensions = {
    LoadBalancer = aws_lb.app.arn_suffix
    TargetGroup  = aws_lb_target_group.app.arn_suffix
  }

  alarm_actions = [aws_autoscaling_policy.scale_out_app.arn]
}

# REQUIRED PREREQUISITES (add if missing):
# resource "aws_lb" "app" {
#   name               = "fastapi-alb"
#   internal           = false
#   load_balancer_type = "application"
#   security_groups    = [aws_security_group.lb.id]
#   subnets            = aws_subnet.public.*.id
# }

# resource "aws_lb_target_group" "app" {
#   name     = "fastapi-tg"
#   port     = 80
#   protocol = "HTTP"
#   vpc_id   = aws_vpc.main.id

#   health_check {
#     path                = "/health"
#     interval            = 30
#     timeout             = 5
#     healthy_threshold   = 2
#     unhealthy_threshold = 2
#     matcher             = "200"
#   }
# }

resource "aws_autoscaling_attachment" "app" {
  autoscaling_group_name = aws_autoscaling_group.app.id
  lb_target_group_arn    = aws_lb_target_group.app.arn
}