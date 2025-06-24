resource "aws_lb" "frontend" {
  name               = var.name
  internal           = var.internal
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets            = var.subnet_ids
  
  enable_deletion_protection = var.enable_deletion_protection
  
  tags = {
    Name = var.name
  }
}

resource "aws_security_group" "alb" {
  name        = "${var.name}-alb-sg"
  description = "Security group for frontend ALB"
  vpc_id      = var.vpc_id
  
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  tags = {
    Name = "${var.name}-alb-sg"
  }
}

resource "aws_lb_target_group" "nginx" {
  name     = "${var.name}-nginx-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = var.vpc_id
  
  health_check {
    path                = var.health_check_path
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
    matcher             = "200"
  }
}

resource "aws_lb_listener" "http" {
  count = var.enable_https ? 1 : 0
  load_balancer_arn = aws_lb.frontend.arn
  port              = "80"
  protocol          = "HTTP"
  
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.nginx.arn
  }
}

# resource "aws_lb_listener" "https" {
#   count             = var.enable_https ? 1 : 0
#   load_balancer_arn = aws_lb.frontend.arn
#   port              = "443"
#   protocol          = "HTTPS"
#   ssl_policy        = "ELBSecurityPolicy-2016-08"
#   certificate_arn   = var.certificate_arn
  
#   default_action {
#     type             = "forward"
#     target_group_arn = aws_lb_target_group.nginx.arn
#   }
# }

# # HTTP to HTTPS redirect
# resource "aws_lb_listener" "http_redirect" {
#   count             = var.enable_https ? 1 : 0
#   load_balancer_arn = aws_lb.frontend.arn
#   port              = 80
#   protocol          = "HTTP"

#   default_action {
#     type = "redirect"
#     redirect {
#       port        = "443"
#       protocol    = "HTTPS"
#       status_code = "HTTP_301"
#     }
#   }
# }