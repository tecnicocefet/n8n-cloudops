output "public_ip" {
  value = aws_eip.n8n_eip.public_ip
}

output "n8n_url_ip" {
  value = "http://${aws_eip.n8n_eip.public_ip}:5678"
}

output "n8n_url" {
  value = "https://${var.dominio}"
}

output "n8n_instance_id" {
  value = aws_instance.n8n.id
}

output "n8n_ebs_volume_id" {
  value = aws_ebs_volume.n8n_data.id
}