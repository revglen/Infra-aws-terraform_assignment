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