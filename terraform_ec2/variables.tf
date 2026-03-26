variable "aws_region" {
  default = "us-east-1"
}

variable "key_name" {
  description = "Nome da key pair da AWS"
}

variable "dominio" {
  type    = string
  default = "agentezap.xyz"
}

variable "az" {
  description = "Availability Zone onde o EBS será criado"
  type        = string
  default     = "us-east-1a"  # default evita perguntas no apply/destroy
}

variable "instance_type" {
  description = "Tipo de instância EC2"
  type        = string
  default     = "t3.micro"
}

variable "ebs_size" {
  description = "Tamanho do disco EBS em GB"
  type        = number
  default     = 20
}

variable "region" {
  type        = string
  description = "Região onde o EBS será criado"
  default     = "us-east-1"
}