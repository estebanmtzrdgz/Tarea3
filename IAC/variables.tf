# ==============================================================================
# Variables de Configuración para el Proyecto (Todas con valores por defecto)
# ==============================================================================

variable "aws_region" {
  description = "Región de AWS donde se desplegarán todos los recursos de infraestructura"
  type        = string
  default     = "us-east-1"
}

variable "key_name" {
  description = "Nombre del Key Pair en AWS para acceder por SSH a la instancia EC2"
  type        = string
  default     = "llave1"
}

variable "ecr_repository_name" {
  description = "Nombre del repositorio Amazon ECR para almacenar la imagen Docker de la aplicación"
  type        = string
  default     = "app-repo"
}

variable "db_name" {
  description = "Nombre de la base de datos inicial de MySQL en RDS"
  type        = string
  default     = "appdb"
}

variable "db_username" {
  description = "Usuario administrador de la base de datos RDS MySQL"
  type        = string
  default     = "admin"
}

variable "db_password" {
  description = "Contraseña para el usuario administrador de RDS MySQL"
  type        = string
  default     = "AdminPass1234!"
  sensitive   = true
}
