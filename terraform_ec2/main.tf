provider "aws" {
  region = var.aws_region
}

resource "aws_security_group" "n8n_sg" {
  name = "n8n-sg"

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["177.142.177.114/32"] # 🔥 importante pra segurança
  }

  ingress {
    description = "n8n"
    from_port   = 5678
    to_port     = 5678
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "n8n" {
  ami           = "ami-0fc5d935ebf8bc3bc" # Ubuntu 22.04 (us-east-1)
  instance_type = "t3.micro"
  key_name      = var.key_name

  subnet_id = "subnet-08e41b6e5ef375613"
  associate_public_ip_address = true

  vpc_security_group_ids = [aws_security_group.n8n_sg.id]

  tags = {
    Name = "n8n-demo"
  }
}