# Variable para el nombre del Key Pair SSH
variable "key_name" {
  description = "Nombre del Key Pair existente en AWS para acceder por SSH"
  type        = string
  default     = "llave1"
}

# 1. Obtener la AMI más reciente de Ubuntu 22.04 LTS (Canonical)
data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] # ID oficial de Canonical
}

# 2. Instancia EC2 tipo micro en la subnet pública con Nginx preinstalado
resource "aws_instance" "web_server" {
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = "t2.micro"
  key_name                    = var.key_name
  subnet_id                   = aws_subnet.public_1.id
  vpc_security_group_ids      = [aws_security_group.web_sg.id]
  associate_public_ip_address = true

  # Script de inicio para instalar y habilitar Nginx
  user_data = <<-EOF
              #!/bin/bash
              apt-get update -y
              apt-get install -y nginx
              systemctl start nginx
              systemctl enable nginx
              EOF

  user_data_replace_on_change = true

  tags = {
    Name = "web-server-nginx"
  }
}

# 3. Outputs útiles
output "ec2_public_ip" {
  description = "Dirección IP pública de la instancia EC2"
  value       = aws_instance.web_server.public_ip
}

output "ec2_public_dns" {
  description = "DNS público de la instancia EC2"
  value       = aws_instance.web_server.public_dns
}
