#!/bin/bash
# Actualizar y instalar Docker
sudo yum update -y
sudo yum install -y docker
# Iniciar y habilitar el servicio de Docker
sudo systemctl start docker
sudo systemctl enable docker
sudo usermod -a -G docker ec2-user
sudo docker run -d -p 80:80 nginx