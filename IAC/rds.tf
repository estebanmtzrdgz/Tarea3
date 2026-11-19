# 1. Grupo de Subnets para RDS (desplegado en subnets privadas de us-east-1a y us-east-1b)
resource "aws_db_subnet_group" "rds_subnet_group" {
  name        = "main-rds-subnet-group"
  description = "Subnet group para RDS MySQL en subnets privadas"
  subnet_ids  = [aws_subnet.private_1.id, aws_subnet.private_2.id]

  tags = {
    Name = "main-rds-subnet-group"
  }
}

# 2. Instancia RDS MySQL (optimizada para Free Tier)
resource "aws_db_instance" "mysql" {
  identifier             = "app-mysql-db"
  engine                 = "mysql"
  engine_version         = "8.0"
  instance_class         = "db.t3.micro"
  allocated_storage      = 20
  max_allocated_storage  = 20
  storage_type           = "gp2"
  db_name                = var.db_name
  username               = var.db_username
  password               = var.db_password
  db_subnet_group_name   = aws_db_subnet_group.rds_subnet_group.name
  vpc_security_group_ids = [aws_security_group.rds_sg.id]
  publicly_accessible    = false
  skip_final_snapshot    = true
  multi_az               = false

  tags = {
    Name = "app-mysql-db"
  }
}

# 3. Outputs de conexión a la base de datos
output "rds_endpoint" {
  description = "Endpoint de conexión completo de RDS (host:puerto)"
  value       = aws_db_instance.mysql.endpoint
}

output "rds_address" {
  description = "Dirección host de la base de datos RDS"
  value       = aws_db_instance.mysql.address
}

output "rds_port" {
  description = "Puerto de conexión de MySQL"
  value       = aws_db_instance.mysql.port
}

output "rds_db_name" {
  description = "Nombre de la base de datos inicial"
  value       = aws_db_instance.mysql.db_name
}
