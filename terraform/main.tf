provider "aws" {
  region = "ap-south-1"
}

variable "my_ip" {
  type = string
}

variable "key_name" {
  type    = string
  default = "mern-key"
}

data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"]

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server-*"]
  }
}

resource "aws_security_group" "web" {
  name        = "terraform-web-sg"
  description = "Terraform test server"

  ingress {
    description = "SSH from my IP only"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.my_ip]
  }

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "Allow all outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "web" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = "t3.micro"
  key_name               = var.key_name
  vpc_security_group_ids = [aws_security_group.web.id]

  user_data = <<-EOT
    #!/bin/bash
    curl -fsSL https://get.docker.com | sh
    usermod -aG docker ubuntu

    mkdir -p /home/ubuntu/app
    cat > /home/ubuntu/app/docker-compose.yml << 'COMPOSE'
    services:
      mongo:
        image: mongo:7
        volumes:
          - mongo-data:/data/db
        restart: unless-stopped
      backend:
        image: abishek0924/mern-tasks-backend:latest
        environment:
          - MONGO_URL=mongodb://mongo:27017/tasksdb
        depends_on:
          - mongo
        restart: unless-stopped
      frontend:
        image: abishek0924/mern-tasks-frontend:latest
        ports:
          - "80:80"
        depends_on:
          - backend
        restart: unless-stopped
    volumes:
      mongo-data:
    COMPOSE

    chown -R ubuntu:ubuntu /home/ubuntu/app
    cd /home/ubuntu/app
    docker compose up -d
  EOT

  tags = {
    Name = "terraform-test-server"
  }
}

resource "aws_eip" "web" {
  instance = aws_instance.web.id
  domain   = "vpc"
}

output "elastic_ip" {
  value = aws_eip.web.public_ip
}
