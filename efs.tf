resource "aws_security_group" "sonarqube_efs" {
  name        = "${var.name_prefix}-efs-sg"
  description = "SG for sonarqube EFS"
  vpc_id      = module.sonarqube_network.vpc_id

  ingress {
    description     = "Allow NFS"
    cidr_blocks     = ["0.0.0.0/0"]
    from_port       = 2049
    to_port         = 2049
    protocol        = "tcp"
    security_groups = [aws_security_group.sonarqube_lb.id]
  }

  egress {
    description     = "Allow NFS"
    from_port       = 2049
    to_port         = 2049
    protocol        = "tcp"
    cidr_blocks     = ["0.0.0.0/0"]
    security_groups = [aws_security_group.sonarqube_lb.id]
  }
}

module "sonarqube_extensions_efs" {
  source           = "cloudposse/efs/aws"
  version          = "0.31.0"
  name             = "${var.name_prefix}_extensions_efs"
  performance_mode = "maxIO"
  region           = var.region
  vpc_id           = module.sonarqube_network.vpc_id
  subnets          = module.sonarqube_network.private_subnets_ids
  security_groups  = [aws_security_group.sonarqube_ecs_sg.id]
}