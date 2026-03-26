#!/bin/bash
set -e

KEY=~/.ssh/funnel_hub.pem
USER=ubuntu

echo "🚀 Subindo infraestrutura..."
terraform -chdir=terraform_ec2 init
terraform -chdir=terraform_ec2 apply -auto-approve

IP=$(terraform -chdir=terraform_ec2 output -raw public_ip)
URL=$(terraform -chdir=terraform_ec2 output -raw n8n_url)

echo "🌐 IP: $IP"
echo "🔗 URL: $URL"

echo "⏳ Aguardando SSH..."
until ssh -i $KEY -o StrictHostKeyChecking=no -o ConnectTimeout=5 $USER@$IP "echo ok" >/dev/null 2>&1; do
  sleep 5
done
echo "✅ SSH pronto!"

echo "⚙️ Setup base..."
ansible-playbook -i "$IP," ansible-ec2-n8n/playbook_setup.yml \
  --private-key $KEY \
  -u $USER \
  -e 'ansible_ssh_common_args="-o StrictHostKeyChecking=no"'

echo "🐳 Containers..."
ansible-playbook -i "$IP," ansible-ec2-n8n/playbook_containers.yml \
  --private-key $KEY \
  -u $USER \
  -e 'ansible_ssh_common_args="-o StrictHostKeyChecking=no"'

echo "🌐 Nginx..."
ansible-playbook -i "$IP," ansible-ec2-n8n/playbook_nginx.yml \
  --private-key $KEY \
  -u $USER \
  -e 'ansible_ssh_common_args="-o StrictHostKeyChecking=no"'

echo "🔒 SSL..."
ansible-playbook -i "$IP," ansible-ec2-n8n/playbook_nginx.yml \
  --private-key $KEY \
  -u $USER \
  -e 'ansible_ssh_common_args="-o StrictHostKeyChecking=no" enable_ssl=true'

echo "🧪 Testando..."
curl -I http://$IP || true
curl -k -I $URL || true

echo "✅ Deploy finalizado!"
echo "🌐 http://$IP"
echo "🔒 $URL"