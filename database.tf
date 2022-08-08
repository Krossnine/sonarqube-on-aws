resource "random_password" "db_master_password" {
  length  = 10
  special = false
}

locals {
  db_password = var.db_password == "" ? random_password.db_master_password.result : var.db_password
}

resource "aws_kms_key" "encryption_key" {
  description         = "Sonar Encryption Key"
  is_enabled          = true
  enable_key_rotation = true

  tags = var.tags
}

resource "aws_db_subnet_group" "aurora_db_subnet_group" {
  name       = "${var.name_prefix}-sonar-aurora-db-subnet-group"
  subnet_ids = module.sonarqube_network.private_subnets_ids

  tags = var.tags
}

resource "aws_security_group" "aurora_sg" {
  name        = "${var.name_prefix}-sonar-aurora-sg"
  description = "Allow traffic to Aurora DB only on PostgreSQL port and only coming from ECS SG"
  vpc_id      = module.sonarqube_network.vpc_id
  ingress {
    protocol  = "tcp"
    from_port = var.db_port
    to_port   = var.db_port
    security_groups = [
      aws_security_group.sonarqube_ecs_sg.id
    ]
  }
  egress {
    protocol    = -1
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = var.tags
}

resource "aws_rds_cluster" "aurora_db" {
  depends_on = [aws_kms_key.encryption_key]

  apply_immediately = true

  # Cluster
  cluster_identifier     = "${var.name_prefix}-aurora-db"
  vpc_security_group_ids = [aws_security_group.aurora_sg.id]
  db_subnet_group_name   = aws_db_subnet_group.aurora_db_subnet_group.id

  # Encryption
  storage_encrypted = true
  kms_key_id        = aws_kms_key.encryption_key.arn

  # Logs
  #enabled_cloudwatch_logs_exports = ["audit", "error", "general"]

  # Database
  engine          = "aurora-postgresql"
  engine_version  = var.db_engine_version
  database_name   = var.db_name
  master_username = var.db_username
  master_password = local.db_password

  # Backups
  backup_retention_period = 3
  preferred_backup_window = "07:00-09:00"
  skip_final_snapshot     = true
  tags                    = var.tags
}

resource "aws_rds_cluster_instance" "aurora_db_cluster_instances" {
  count                = length(module.sonarqube_network.availability_zones)
  identifier           = "aurora-db-instance-${count.index}"
  cluster_identifier   = aws_rds_cluster.aurora_db.id
  db_subnet_group_name = aws_db_subnet_group.aurora_db_subnet_group.id
  engine               = "aurora-postgresql"
  engine_version       = var.db_engine_version
  instance_class       = var.db_instance_size
  publicly_accessible  = false
  tags                 = var.tags
}
