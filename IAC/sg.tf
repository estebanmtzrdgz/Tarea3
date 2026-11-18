# 1. Grupo de seguridad para la instancia EC2 (HTTP y SSH)
resource "aws_security_group" "web_sg" {
  name        = "web-server-sg"
  description = "Permitir trafico HTTP y SSH entrante, y todo el trafico saliente"
  vpc_id      = aws_vpc.main.id

  # Permitir HTTP (puerto 80)
  ingress {
    description = "HTTP desde cualquier lugar"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Permitir SSH (puerto 22)
  ingress {
    description = "SSH desde cualquier lugar"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Tráfico saliente permitido (necesario para descargar e instalar Nginx)
  egress {
    description = "Permitir todo el trafico de salida"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "web-server-security-group"
  }
}

# 2. Grupo de seguridad para el Application Load Balancer (ALB)
resource "aws_security_group" "alb_sg" {
  name        = "alb-security-group"
  description = "Permitir trafico HTTP entrante desde Internet hacia el ALB"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "HTTP desde Internet"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "Permitir todo el trafico de salida hacia los destinos"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "alb-security-group"
  }
}

# 3. Grupo de seguridad para las tareas/contenedores ECS (solo acepta tráfico del ALB)
resource "aws_security_group" "ecs_tasks_sg" {
  name        = "ecs-tasks-security-group"
  description = "Permitir trafico entrante hacia los contenedores unicamente desde el ALB"
  vpc_id      = aws_vpc.main.id

  ingress {
    description     = "HTTP solo desde el Security Group del ALB"
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.alb_sg.id]
  }

  egress {
    description = "Permitir salida a Internet (via NAT Gateway para ECR, CloudWatch, etc.)"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "ecs-tasks-security-group"
  }
}


# 4. Grupo de seguridad para la base de datos RDS MySQL
resource "aws_security_group" "rds_sg" {
  name        = "rds-mysql-security-group"
  description = "Permitir trafico MySQL (puerto 3306) desde ECS y EC2"
  vpc_id      = aws_vpc.main.id

  ingress {
    description     = "MySQL desde las tareas ECS y servidor EC2"
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [
      aws_security_group.ecs_tasks_sg.id,
      aws_security_group.web_sg.id
    ]
  }

  egress {
    description = "Permitir todo el trafico de salida"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "rds-mysql-security-group"
  }
}
