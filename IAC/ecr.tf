# Variable para el nombre del repositorio ECR
variable "ecr_repository_name" {
  description = "Nombre del repositorio ECR para la aplicación"
  type        = string
  default     = "app-repo"
}

# 1. Repositorio ECR
resource "aws_ecr_repository" "app_repo" {
  name                 = var.ecr_repository_name
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = {
    Name = var.ecr_repository_name
  }
}

# 2. Política del ciclo de vida para limitar a un máximo de 2 imágenes (free tier friendly)
resource "aws_ecr_lifecycle_policy" "app_repo_lifecycle_policy" {
  repository = aws_ecr_repository.app_repo.name

  policy = jsonencode({
    rules = [
      {
        rulePriority = 1
        description  = "Mantener unicamente las ultimas 2 imagenes"
        selection = {
          tagStatus   = "any"
          countType   = "imageCountMoreThan"
          countNumber = 2
        }
        action = {
          type = "expire"
        }
      }
    ]
  })
}

# 3. Outputs útiles para Docker / CI/CD
output "ecr_repository_url" {
  description = "URL del repositorio ECR para etiquetar y subir las imágenes Docker"
  value       = aws_ecr_repository.app_repo.repository_url
}

output "ecr_repository_arn" {
  description = "ARN del repositorio ECR"
  value       = aws_ecr_repository.app_repo.arn
}
