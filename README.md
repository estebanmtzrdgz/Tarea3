# Tarea 3: Arquitectura en la Nube con AWS, Terraform y CI/CD

Este repositorio contiene la solución integral para el despliegue automatizado de infraestructura como código (IaC), una aplicación web contenerizada y un pipeline de entrega continua (CI/CD) en Amazon Web Services (AWS).

---

## 🏛️ Arquitectura de la Solución

```
                                  INTERNET
                                     │
                        ┌────────────┴────────────┐
                        │ Internet Gateway (IGW)  │
                        └────────────┬────────────┘
                                     │
           ┌─────────────────────────┴─────────────────────────┐
           │                     VPC (10.0.0.0/16)             │
           │                                                   │
           │  ┌─────────────────────────┬───────────────────┐  │
           │  │   Zona: us-east-1a      │ Zona: us-east-1b  │  │
           │  ├─────────────────────────┼───────────────────┤  │
           │  │ [Subnet Pública 1]      │ [Subnet Pública 2]│  │
           │  │  • Application LB (ALB) │  • Application LB │  │
           │  │  • NAT Gateway 1        │  • NAT Gateway 2  │  │
           │  │  • Instancia EC2 Ubuntu │                   │  │
           │  ├─────────────────────────┼───────────────────┤  │
           │  │ [Subnet Privada 1]      │ [Subnet Privada 2]│  │
           │  │  • Tarea ECS Fargate 1  │ • Tarea Fargate 2 │  │
           │  │  • RDS MySQL (Subnet)   │ • RDS MySQL (Sub) │  │
           │  └─────────────────────────┴───────────────────┘  │
           └───────────────────────────────────────────────────┘
                                     │
                 ┌───────────────────┴───────────────────┐
                 │ ECR (app-repo)   │ CloudWatch Logs    │
                 └───────────────────┴───────────────────┘
```

### Componentes Principales:
1. **Red y Conectividad (VPC):**
   - VPC `10.0.0.0/16` con soporte y nombres de host DNS habilitados.
   - **2 Subnets Públicas** (`10.0.1.0/24` en `us-east-1a` y `10.0.2.0/24` en `us-east-1b`).
   - **2 Subnets Privadas** (`10.0.11.0/24` en `us-east-1a` y `10.0.12.0/24` en `us-east-1b`).
   - **1 Internet Gateway** para el tráfico público.
   - **2 NAT Gateways** con Elastic IPs asignadas en cada subnet pública para otorgar salida segura a Internet desde las subnets privadas (alta disponibilidad).
   - Tablas de enrutamiento públicas y privadas con sus respectivas asociaciones explícitas.

2. **Seguridad (Security Groups):**
   - `web-server-sg`: Acceso SSH (puerto 22) y HTTP (puerto 80) hacia la instancia EC2.
   - `alb_sg`: Tráfico HTTP público (puerto 80) hacia el Application Load Balancer.
   - `ecs_tasks_sg`: Tráfico HTTP en puerto 80 **únicamente** desde el Security Group del ALB. Salida total a Internet vía NAT.
   - `rds_sg`: Acceso a MySQL (puerto 3306) **exclusivamente** desde los Security Groups de las tareas ECS y del servidor EC2.

3. **Cómputo y Contenedores:**
   - **Instancia EC2:** Ubuntu 22.04 LTS tipo `t3.micro` con Nginx preinstalado vía `user_data` y acceso mediante Key Pair.
   - **Repositorio ECR:** `app-repo` con política de ciclo de vida que conserva un máximo de **2 imágenes** (optimizado para el nivel gratuito).
   - **Clúster ECS & Fargate:** Servicio con 2 contenedores distribuidos en las subnets privadas, registrado en el Target Group del ALB y con registro de eventos en CloudWatch Logs (retención de 7 días).
   - **Rol de IAM:** Rol de ejecución `ecs-execution-role` con permisos administrados para descargar imágenes de ECR y emitir logs.

4. **Base de Datos:**
   - **RDS MySQL 8.0:** Tipo `db.t3.micro`, almacenamiento de 20 GB `gp2`, ubicada de forma aislada en las subnets privadas sin acceso público directo (`publicly_accessible = false`).

---

## 📁 Estructura del Repositorio

```text
├── .github/
│   └── workflows/
│       └── deploy.yml          # Pipeline de GitHub Actions (Build y Push a ECR)
├── APP/
│   ├── Dockerfile              # Imagen ligera basada en nginx:alpine
│   ├── index.html              # Página web de bienvenida personalizada
│   └── README.md               # Guía de la aplicación contenerizada
├── IAC/
│   ├── main.tf                 # Proveedor AWS, VPC, Subnets, IGW, NAT GW y Enrutamiento
│   ├── variables.tf            # Variables centralizadas con valores por defecto
│   ├── sg.tf                   # Todos los Security Groups del proyecto
│   ├── ec2.tf                  # Instancia EC2 con Ubuntu y Nginx
│   ├── ecr.tf                  # Repositorio ECR y ciclo de vida de imágenes
│   ├── ecs.tf                  # ALB, Listener, Target Group, Clúster y Servicio Fargate
│   ├── rds.tf                  # Instancia RDS MySQL y Subnet Group privado
│   └── llave1.pem              # Clave privada SSH para la EC2 (ignorada por Git)
├── .gitignore                  # Exclusiones de Git (estados de terraform, *.pem, etc.)
└── README.md                   # Documentación general del proyecto
```

---

## ⚙️ Variables de Terraform

Todas las variables tienen un **valor por defecto**, garantizando que `terraform plan` y `terraform apply` nunca fallen por falta de parámetros:

| Variable | Descripción | Tipo | Valor por Defecto |
| :--- | :--- | :---: | :--- |
| `aws_region` | Región de AWS donde se despliegan los recursos | `string` | `"us-east-1"` |
| `key_name` | Nombre del Key Pair en AWS para SSH | `string` | `"llave1"` |
| `ecr_repository_name` | Nombre del repositorio Amazon ECR | `string` | `"app-repo"` |
| `db_name` | Nombre de la base de datos MySQL inicial | `string` | `"appdb"` |
| `db_username` | Usuario administrador de la base de datos | `string` | `"admin"` |
| `db_password` | Contraseña de administración de MySQL | `string` | `"AdminPass1234!"` *(Sensible)* |

> Si deseas personalizar algún valor, crea un archivo `IAC/terraform.tfvars` o pasa el parámetro por CLI:
> ```bash
> terraform apply -var="db_password=OtraContraseñaSegura123!"
> ```

---

## 🚀 Guía de Despliegue Paso a Paso

### 1. Requisitos Previos
- **AWS CLI v2** instalado y autenticado con credenciales con permisos suficientes (`aws configure`).
- **Terraform** (versión >= 1.0.0).
- **Git**.
- **Docker** (opcional, para compilar o probar localmente).

### 2. Clonar el Repositorio
```bash
git clone https://github.com/estebanmtzrdgz/Tarea3.git
cd Tarea3
```

### 3. Desplegar la Infraestructura con Terraform
Ingresa al directorio de infraestructura y ejecuta:

```bash
cd IAC

# Inicializar Terraform y descargar proveedores
terraform init

# Validar la sintaxis y coherencia de las configuraciones
terraform validate

# Comprobar el plan de ejecución (no requerirá entradas manuales)
terraform plan

# Aplicar los cambios y crear los recursos en AWS
terraform apply -auto-approve
```

Al finalizar, Terraform mostrará las URLs y endpoints creados:
```text
Outputs:
alb_url            = "http://app-alb-XXXXXXXXXX.us-east-1.elb.amazonaws.com"
ec2_public_ip      = "X.X.X.X"
ecr_repository_url = "XXXXXXXXXXXX.dkr.ecr.us-east-1.amazonaws.com/app-repo"
rds_endpoint       = "app-mysql-db.XXXXXXXXXXXX.us-east-1.rds.amazonaws.com:3306"
```

### 4. Configurar el Pipeline de CI/CD en GitHub Actions
Para que cada `push` o `pull_request` a la rama `main` actualice la aplicación en ECR automáticamente:

1. Ve a tu repositorio en GitHub: **Settings** > **Secrets and variables** > **Actions**.
2. Haz clic en **New repository secret** y añade:
   - `AWS_ACCESS_KEY_ID`: Tu Access Key ID de AWS.
   - `AWS_SECRET_ACCESS_KEY`: Tu Secret Access Key de AWS.
3. Al realizar un cambio en la carpeta `APP/` y hacer `git push origin main`, el workflow compilará la imagen de Docker y la subirá a ECR etiquetada como `:latest` y con el hash del commit.
4. El servicio ECS Fargate actualizará automáticamente los contenedores con la nueva imagen.

---

## 🔍 Verificación y Pruebas

### Probar la Aplicación Web (ALB)
Abre en tu navegador la URL devuelta por el output `alb_url` o realiza una consulta con curl:
```bash
curl -I http://<ALB_DNS_NAME>
```
Respuesta esperada: `HTTP/1.1 200 OK`.

### Conectarse a la Instancia EC2 por SSH
Usa la clave `llave1.pem` generada y la IP pública de la instancia:
```bash
ssh -i IAC/llave1.pem ubuntu@<EC2_PUBLIC_IP>
```

### Conectarse a la Base de Datos RDS MySQL
Desde la instancia EC2 (o desde un contenedor con acceso a la red privada):
```bash
mysql -h <RDS_ENDPOINT_HOST> -P 3306 -u admin -p
```
Ingresa la contraseña configurada (`AdminPass1234!`).

---

## 🧹 Limpieza de Recursos (Destroy)

Para evitar consumos o cargos en tu cuenta de AWS una vez concluida la revisión o prueba:

```bash
cd IAC
terraform destroy -auto-approve
```
*(Esto desaprovisionará la VPC, los NAT Gateways, ALB, clúster ECS, la base de datos RDS y la instancia EC2 de forma limpia).*
