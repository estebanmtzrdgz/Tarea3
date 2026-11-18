# Aplicación Web Ligera (Nginx) - Tarea 3

Esta aplicación consiste en un servidor web Nginx contenerizado con una página de bienvenida estilizada, diseñada para desplegarse en AWS ECS Fargate a través del repositorio ECR configurado en Terraform.

## Estructura de archivos
- [index.html](file:///C:/Users/esteb/OneDrive/Documentos/Tarea3/APP/index.html): Página de bienvenida web estilizada.
- [Dockerfile](file:///C:/Users/esteb/OneDrive/Documentos/Tarea3/APP/Dockerfile): Imagen Docker basada en `nginx:alpine` expuesta en el puerto `80`.

## Comandos para compilar y subir a AWS ECR

1. **Obtener la URL del repositorio ECR** (desde la carpeta `IAC`):
   ```bash
   cd ../IAC
   terraform output -raw ecr_repository_url
   ```

2. **Autenticarse con AWS ECR en Docker**:
   ```bash
   aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin <TU_ECR_URL>
   ```

3. **Construir la imagen Docker** (desde la carpeta `APP`):
   ```bash
   cd ../APP
   docker build -t app-repo:latest .
   ```

4. **Etiquetar la imagen para ECR**:
   ```bash
   docker tag app-repo:latest <TU_ECR_URL>:latest
   ```

5. **Subir la imagen a ECR**:
   ```bash
   docker push <TU_ECR_URL>:latest
   ```
