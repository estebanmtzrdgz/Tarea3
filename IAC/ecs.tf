# 1. Application Load Balancer (ALB) en las subnets públicas
resource "aws_lb" "main_alb" {
  name               = "app-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  subnets            = [aws_subnet.public_1.id, aws_subnet.public_2.id]

  tags = {
    Name = "app-alb"
  }
}

# 2. Grupo de destinos (Target Group) tipo IP para ECS Fargate
resource "aws_lb_target_group" "app_tg" {
  name        = "app-target-group"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = aws_vpc.main.id
  target_type = "ip"

  health_check {
    path                = "/"
    protocol            = "HTTP"
    matcher             = "200-399"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 3
  }

  tags = {
    Name = "app-target-group"
  }
}

# 3. Listener del ALB en el puerto 80
resource "aws_lb_listener" "app_listener" {
  load_balancer_arn = aws_lb.main_alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app_tg.arn
  }
}

# 4. Grupo de logs de CloudWatch con retención de 7 días
resource "aws_cloudwatch_log_group" "ecs_log_group" {
  name              = "/ecs/app-task"
  retention_in_days = 7

  tags = {
    Name = "ecs-app-log-group"
  }
}

# 5. Rol de IAM para la ejecución de tareas de ECS (descargar de ECR y escribir logs en CloudWatch)
resource "aws_iam_role" "ecs_execution_role" {
  name = "ecs-execution-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name = "ecs-execution-role"
  }
}

resource "aws_iam_role_policy_attachment" "ecs_execution_role_policy" {
  role       = aws_iam_role.ecs_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# 6. Clúster de ECS
resource "aws_ecs_cluster" "main_cluster" {
  name = "app-cluster"

  tags = {
    Name = "app-cluster"
  }
}

# 7. Definición de la tarea (Task Definition) con imagen :latest del repositorio ECR
resource "aws_ecs_task_definition" "app_task" {
  family                   = "app-task"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256"
  memory                   = "512"
  execution_role_arn       = aws_iam_role.ecs_execution_role.arn

  container_definitions = jsonencode([
    {
      name      = "app-container"
      image     = "${aws_ecr_repository.app_repo.repository_url}:latest"
      essential = true
      portMappings = [
        {
          containerPort = 80
          hostPort      = 80
          protocol      = "tcp"
        }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.ecs_log_group.name
          "awslogs-region"        = "us-east-1"
          "awslogs-stream-prefix" = "ecs"
        }
      }
    }
  ])

  tags = {
    Name = "app-task-definition"
  }
}

# 8. Servicio de ECS con 2 contenedores en las subnets privadas (us-east-1a y us-east-1b)
resource "aws_ecs_service" "app_service" {
  name            = "app-service"
  cluster         = aws_ecs_cluster.main_cluster.id
  task_definition = aws_ecs_task_definition.app_task.arn
  desired_count   = 2
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = [aws_subnet.private_1.id, aws_subnet.private_2.id]
    security_groups  = [aws_security_group.ecs_tasks_sg.id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.app_tg.arn
    container_name   = "app-container"
    container_port   = 80
  }

  # Espera explícita a que existan las rutas de las subnets privadas (asociaciones y NAT gateways)
  # y el listener del ALB para que los contenedores puedan salir por el NAT a descargar la imagen ECR
  depends_on = [
    aws_route_table_association.private_1,
    aws_route_table_association.private_2,
    aws_lb_listener.app_listener
  ]

  tags = {
    Name = "app-ecs-service"
  }
}

# 9. Output de la URL del ALB
output "alb_url" {
  description = "URL del Application Load Balancer"
  value       = "http://${aws_lb.main_alb.dns_name}"
}

output "alb_dns_name" {
  description = "Nombre DNS del Application Load Balancer"
  value       = aws_lb.main_alb.dns_name
}
