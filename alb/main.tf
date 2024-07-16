resource "aws_security_group" "lb_sg" {
  name        = "${var.app_name}-lb-sg"
  description = "Load balancer security group"
  vpc_id      = var.vpc_id

  tags = {
    Name = "${var.app_name}-lb-sg"
  }
}

resource "aws_vpc_security_group_ingress_rule" "allow_tcp_traffic" {
  security_group_id = aws_security_group.lb_sg.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 80
  to_port           = 80
  ip_protocol       = "tcp"
}

resource "aws_vpc_security_group_egress_rule" "allow_all_traffic_lb" {
  security_group_id = aws_security_group.lb_sg.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}

resource "aws_lb" "load_balancer" {
  name              = "${var.app_name}-load-balancer"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.lb_sg.id]
  subnets            = var.public_subnet_ids
} 

resource "aws_lb_target_group" "api" {
  name     = "${var.app_name}-api-target-group"
  port     = 3000
  protocol = "HTTP"
  vpc_id   = var.vpc_id

  health_check {
    path = "/api"
  }
}

resource "aws_lb_target_group_attachment" "api_attachment" {
  count             = 2
  target_group_arn  = aws_lb_target_group.api.arn
  target_id         = var.instance_ids[count.index]
  port              = 3000
}

resource "aws_lb_target_group" "frontend" {
  name     = "${var.app_name}-frontend-target-group"
  port     = 80
  protocol = "HTTP"
  vpc_id   = var.vpc_id

  health_check {
    path = "/"
  }
}

resource "aws_lb_target_group_attachment" "frontend_attachment" {
  count             = 2
  target_group_arn  = aws_lb_target_group.frontend.arn
  target_id         = var.instance_ids[count.index]
  port              = 80
}

resource "aws_lb_listener" "listener" {
  load_balancer_arn = aws_lb.load_balancer.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.frontend.arn
  }
}

resource "aws_lb_listener_rule" "api" {
  listener_arn = aws_lb_listener.listener.arn

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.api.arn
  }

  condition {
    path_pattern {
      values = ["/api/*"]
    }
  }
}