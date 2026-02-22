# --- Load Balancer --- #

resource "aws_security_group" "lb_sg" {
  name        = "dev-lb-sg"
  description = "Allow HTTPS traffic to the load balancer"
  vpc_id      = aws_vpc.dev_vpc.id

  ingress {
    from_port   = 443
    to_port     = 443
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
    Name        = "dev-lb-sg"
  }
}

resource "aws_lb" "dev_alb" {
  name                = "dev-app-load-balancer"
  internal            = false
  load_balancer_type  = "application"
  security_groups     = [aws_security_group.lb_sg.id]
  subnets             = [aws_subnet.dev_public_subnet.id]

  tags = {
    Name        = "dev_alb"
  }
}

resource "aws_lb_target_group" "dev_tg" {
  name                = "dev-app-tg"
  port                = 80
  protocol            = "TCP"
  vpc_id              = aws_vpc.dev_vpc.id

  health_check {
    path                = "/"
    protocol            = "HTTP"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }
}

resource "aws_lb_listener" "https_listener" {
  load_balancer_arn = aws_lb.dev_alb.arn
  port              = 443 
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  certificate_arn   = "arn:aws:acm:us-east-2:538494149300:certificate/9f0fc060-1514-433d-b048-81743158ac77" 

  default_action {
    type              = "forward"
    target_group_arn  = aws_lb_target_group.dev_tg.arn
  }
}

resource "aws_lb_target_group_attachment" "attachment" {
  count = length(aws_instance.web_server_dev)
  target_group_arn = aws_lb_target_group.dev_tg.arn
  target_id        = aws_instance.web_server_dev[count.index].id
  port             = 80

}


# --- DNS --- #

data "aws_route53_zone" "my_domain" {
  name = "cbcnet.me" 
}

resource "aws_route53_record" "dev_app" {
  zone_id = data.aws_route53_zone.my_domain.zone_id
  name    = "dev.${data.aws_route53_zone.my_domain.name}"
  type    = "A"

  alias {
    name                   = aws_lb.dev_alb.dns_name
    zone_id                = aws_lb.dev_alb.zone_id
    evaluate_target_health = true
  }
}
