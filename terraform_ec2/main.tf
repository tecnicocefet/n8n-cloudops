provider "aws" {
  region = var.aws_region
}

# 🔐 Security Group
resource "aws_security_group" "n8n_sg" {
  name = "n8n-sg"

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["177.142.177.114/32"]
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

# 🖥️ EC2
resource "aws_instance" "n8n" {
  ami           = "ami-0fc5d935ebf8bc3bc"
  instance_type = "t3.micro"
  key_name      = var.key_name

  subnet_id                   = "subnet-08e41b6e5ef375613"
  associate_public_ip_address = false

  vpc_security_group_ids = [aws_security_group.n8n_sg.id]

  tags = {
    Name = "n8n-demo"
  }
}

# 🌍 Elastic IP (IP fixo)
resource "aws_eip" "n8n_eip" {
  domain = "vpc"
}

resource "aws_eip_association" "n8n_eip_assoc" {
  instance_id   = aws_instance.n8n.id
  allocation_id = aws_eip.n8n_eip.id
}

# 💾 EBS (disco persistente)
resource "aws_ebs_volume" "n8n_data" {
  availability_zone = var.az
  size              = var.ebs_size

  # Temporariamente removemos prevent_destroy
  # lifecycle {
  #   prevent_destroy = true
  # }

  tags = {
    Name = "n8n-data"
  }
}

# 📎 Attach do EBS à EC2
resource "aws_volume_attachment" "n8n_data_attach" {
  device_name = "/dev/sdh"              # ou outro device que você queira
  volume_id   = aws_ebs_volume.n8n_data.id
  instance_id = aws_instance.n8n.id
  force_detach = true                    # só se precisar forçar o attach caso esteja anexado a outro
}