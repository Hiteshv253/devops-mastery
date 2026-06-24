# Application Load Balancer
resource "aws_lb" "weather_app" {
  name               = "${var.project_name}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.lb.id]
  subnets            = aws_subnet.public[*].id

  enable_deletion_protection = false

  tags = {
    Name        = "${var.project_name}-alb"
    Environment = var.environment
  }
}

# Target Group
resource "aws_lb_target_group" "weather_app" {
  name        = "${var.project_name}-tg"
  port        = 8000
  protocol    = "HTTP"
  vpc_id      = aws_vpc.main.id
  target_type = "ip"

  health_check {
    enabled             = true
    healthy_threshold   = 2
    unhealthy_threshold = 3
    interval            = 30
    path                = "/"
    port                = 8000
    protocol            = "HTTP"
    matcher {
      status_code = "200"
    }
  }

  tags = {
    Name        = "${var.project_name}-tg"
    Environment = var.environment
  }
}

# Load Balancer Listener
resource "aws_lb_listener" "weather_app" {
  load_balancer_arn = aws_lb.weather_app.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.weather_app.arn
  }
}

# Load Balancer Listener (HTTPS - Optional)
resource "aws_lb_listener" "weather_app_https" {
  load_balancer_arn = aws_lb.weather_app.arn
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  certificate_arn   = var.acm_certificate_arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.weather_app.arn
  }

  count = var.acm_certificate_arn != "" ? 1 : 0
}

variable "acm_certificate_arn" {
  description = "ACM certificate ARN for HTTPS"
  type        = string
  default     = ""
}
