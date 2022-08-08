resource "aws_security_group" "sonarqube_lb" {
  name        = "${var.name_prefix}-lb-sg"
  description = "SG for sonarqube load balancer"
  vpc_id      = module.sonarqube_network.vpc_id

  ingress {
    protocol    = "tcp"
    from_port   = 80
    to_port     = 80
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    protocol    = -1
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = var.tags
}

module "sonar_alb" {
  source             = "terraform-aws-modules/alb/aws"
  name               = "${var.name_prefix}-alb"
  load_balancer_type = "application"
  vpc_id             = module.sonarqube_network.vpc_id
  subnets            = module.sonarqube_network.public_subnets_ids
  security_groups    = [aws_security_group.sonarqube_lb.id]

  http_tcp_listeners = [
    {
      port               = 80
      protocol           = "HTTP"
      target_group_index = 0
    }
  ]

  target_groups = [
    {
      name_prefix          = "pref-"
      backend_protocol     = "HTTP"
      backend_port         = var.sonar_port
      target_type          = "ip"
      deregistration_delay = 10
      health_check = {
        enabled             = true
        interval            = 300
        path                = "/api/system/status"
        port                = "traffic-port"
        healthy_threshold   = 3
        unhealthy_threshold = 3
        timeout             = 6
        protocol            = "HTTP"
        matcher             = "200-399"
      }
    }
  ]

  tags = var.tags
}
