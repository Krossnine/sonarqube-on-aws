resource "aws_ecs_cluster" "sonarqube_ecs_cluster" {
  name = var.name_prefix
  tags = var.tags
}

resource "aws_security_group" "sonarqube_ecs_sg" {
  name        = "${var.name_prefix}-ecs-tasks-sg"
  vpc_id      = module.sonarqube_network.vpc_id

  ingress {
    protocol        = "tcp"
    from_port       = var.sonar_port
    to_port         = var.sonar_port
    cidr_blocks     = ["0.0.0.0/0"]
    security_groups = [aws_security_group.sonarqube_lb.id]
  }

  ingress {
    description     = "Allow access to Aurora PGSQL"
    protocol        = "tcp"
    from_port       = var.db_port
    to_port         = var.db_port
    cidr_blocks     = ["0.0.0.0/0"]
    security_groups = [aws_security_group.sonarqube_lb.id]
  }

  ingress {
    description     = "Allow NFS"
    protocol        = "tcp"
    from_port       = 2049
    to_port         = 2049
    cidr_blocks     = ["0.0.0.0/0"]
    security_groups = [aws_security_group.sonarqube_lb.id]
  }

  egress {
    protocol    = -1
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = var.tags
}

resource "aws_ecs_service" "sonarqube_ecs_service" {
  name                 = "${var.name_prefix}_ecs"
  cluster              = aws_ecs_cluster.sonarqube_ecs_cluster.id
  task_definition      = aws_ecs_task_definition.sonarqube_task.arn
  launch_type          = "FARGATE"
  platform_version     = "1.4.0"
  desired_count        = 1
  force_new_deployment = true

  network_configuration {
    assign_public_ip = false
    subnets          = module.sonarqube_network.private_subnets_ids
    security_groups = [
      aws_security_group.sonarqube_ecs_sg.id
    ]
  }

  load_balancer {
    target_group_arn = element(module.sonar_alb.target_group_arns, 0)
    container_name   = var.name_prefix
    container_port   = var.sonar_port
  }

  tags = var.tags
}

data "aws_iam_policy_document" "sonarqube_ecs_task_execution_role" {
  version = "2012-10-17"
  statement {
    sid     = ""
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "sonarqube_ecs_task_execution_role" {
  name               = "${var.name_prefix}-ecsTaskExecutionRole"
  assume_role_policy = data.aws_iam_policy_document.sonarqube_ecs_task_execution_role.json
  tags               = var.tags
}

resource "aws_iam_role_policy_attachment" "sonarqube_ecs_task_execution_role" {
  role       = aws_iam_role.sonarqube_ecs_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}


resource "aws_iam_role_policy_attachment" "ecs_task_execution_role_efs" {
  role       = aws_iam_role.sonarqube_ecs_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonElasticFileSystemClientFullAccess"
}

resource "aws_ecs_task_definition" "sonarqube_task" {
  family                   = "sonarqube"
  network_mode             = "awsvpc"
  cpu                      = var.sonar_task_cpu
  memory                   = var.sonar_task_memory
  requires_compatibilities = ["FARGATE"]
  task_role_arn            = aws_iam_role.sonarqube_ecs_task_execution_role.arn
  execution_role_arn       = aws_iam_role.sonarqube_ecs_task_execution_role.arn

  volume {
    name = "sonarqube_extensions"
    efs_volume_configuration {
      file_system_id     = module.sonarqube_extensions_efs.id
      root_directory     = "/"
      transit_encryption = "DISABLED"
    }
  }

  container_definitions = jsonencode([
    {
      name      = var.name_prefix
      image     = var.sonar_image
      essential = true
      command : [
        "-Dsonar.search.javaAdditionalOpts=-Dnode.store.allow_mmap=false"
      ]
      mountPoints : [
        {
          sourceVolume : "sonarqube_extensions",
          containerPath : "/opt/sonarqube/extensions",
          readOnly : false
        }
      ],
      ulimits = [
        {
          "name" : "nofile",
          "softLimit" : 65535,
          "hardLimit" : 65535
        }
      ]
      portMappings = [
        {
          containerPort = 9000
          hostPort      = var.sonar_port
          protocol      = "tcp"
        }
      ]
      environment = [
        {
          name  = "SONAR_JDBC_USERNAME"
          value = var.db_username
        },
        {
          name  = "SONAR_JDBC_PASSWORD"
          value = local.db_password
        },
        {
          name  = "SONAR_JDBC_URL"
          value = "jdbc:postgresql://${aws_rds_cluster.aurora_db.endpoint}/${var.db_name}?sslmode=require"
        },
      ]
      logConfiguration = {
        logDriver = "awslogs",
        "options" = {
          "awslogs-group"         = aws_cloudwatch_log_group.sonarqube_log_group.name
          "awslogs-stream-prefix" = var.name_prefix
          "awslogs-region"        = var.region
        }
      }
    }
  ])

  tags = var.tags
}
