# 24-alb.tf

## local variable
/*
  public_subnet_ids : public subnet ids in same VPC  || ["subnet-0xxxxx",...] || [aws_subnet.public_A.id, ...]
  idle_timeout : Application LoadBalancer timeout value
  lb_enable_http2 : enable http2 true/false
  lb_enable_deletion_protection : When someone delete this ApplicationLoadBalancer, protect or not
  vpc_id : VPC id
           [Priority] aws_vpc.this.id > local.vpc_id > "vpc-0xxxxxxxx"
  target_group_port : Port for target group
  health_check_path : Path for health check worker node
  listener_http_port : Port for http listener
  listener_https_port : Port for https listener
  route53_certificate_arn : ARN for route53 certificate value. There is a guide on upper side.
*/


locals {
  idle_timeout                  = 60
  lb_enable_http2               = true
  lb_enable_deletion_protection = false
  target_group_port             = 32000
  health_check_path             = "/healthz"
  listener_http_port            = 80
  listener_https_port           = 443
  ssl_policy                    = "ELBSecurityPolicy-2016-08"
}

## create ALB
resource "aws_lb" "main" {
  name               = "${local.upper_name}-ALB"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id, aws_security_group.worker.id]
  subnets            = var.public_subnet_ids

  ## Optional Arguments
  idle_timeout               = local.idle_timeout
  enable_http2               = local.lb_enable_http2
  enable_deletion_protection = local.lb_enable_deletion_protection

  tags = {
      "Name" = "${local.upper_name}-ALB"
  }    
}

resource "aws_security_group" "alb" {
  vpc_id = var.vpc_id
  name   = "${local.upper_name}-ALB"

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "TCP"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "TCP"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
      "Name" = "${local.upper_name}-ALB"
  }
    
  
  
}

resource "aws_lb_target_group" "tg_http" {
  name     = "${local.upper_name}-ALB"
  vpc_id   = var.vpc_id
  port     = local.target_group_port
  protocol = "HTTP"

  health_check {
    interval            = 30
    path                = local.health_check_path
    port                = "traffic-port"
    protocol            = "HTTP"
    timeout             = 5
    healthy_threshold   = 3
    unhealthy_threshold = 3
    matcher             = 200
  }

  target_type = "instance"

  ## Create new target group before destroy current target group
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_lb_listener" "frontend_http" {
  load_balancer_arn = aws_lb.main.arn
  port              = local.listener_http_port
  protocol          = "HTTP"

  default_action {
    target_group_arn = aws_lb_target_group.tg_http.id
    type             = "forward"
  }
}

resource "aws_lb_listener" "frontend_https" {
  load_balancer_arn = aws_lb.main.arn
  port              = local.listener_https_port
  protocol          = "HTTPS"
  certificate_arn   = aws_acm_certificate.default.arn
  # 	arn:aws:acm:ap-northeast-2:759871273906:certificate/780df33f-45b2-4a6f-a5c4-9b6f4c4e7d55
  #   arn:aws:acm:ap-northeast-2:759871273906:certificate/780df33f-45b2-4a6f-a5c4-9b6f4c4e7d55
  ssl_policy        = local.ssl_policy

  default_action {
    target_group_arn = aws_lb_target_group.tg_http.arn
    type             = "forward"
  }
}

resource "aws_lb_listener_certificate" "https_listener_no_logs" {
  listener_arn    = aws_lb_listener.frontend_https.arn
  certificate_arn = aws_acm_certificate.default.arn
}
