#!/bin/bash
set -e

# ===============================
# Configurações
# ===============================
KEY=~/.ssh/funnel_hub.pem
USER=ubuntu
DOMINIO="agentezap.xyz"

command -v dig >/dev/null 2>&1 || {
  echo "❌ dig não encontrado. Instale com: sudo apt install dnsutils"
  exit 1
}

# ===============================
# Terraform
# ===============================
echo "🚀 Inicializando Terraform..."
terraform -chdir=terraform_ec2 init

echo "📦 Aplicando infraestrutura..."
terraform -chdir=terraform_ec2 apply -auto-approve

IP=$(terraform -chdir=terraform_ec2 output -raw public_ip)

trap 'echo ""; echo "🔐 SSH:"; echo "ssh -i '"$KEY"' '"$USER"'@'"$IP"'"' EXIT

echo "🌐 IP criado: $IP"

# ===============================
# Espera SSH
# ===============================
echo "⏳ Aguardando SSH..."
until ssh -i $KEY -o StrictHostKeyChecking=no -o ConnectTimeout=5 $USER@$IP "echo ok" >/dev/null 2>&1; do
  sleep 5
  echo "🔄 aguardando SSH..."
done
echo "✅ SSH pronto!"

# ===============================
# Espera cloud-init
# ===============================
echo "⏳ Aguardando cloud-init..."
until ssh -i $KEY -o StrictHostKeyChecking=no -o ConnectTimeout=5 $USER@$IP \
"cloud-init status --wait" >/dev/null 2>&1; do
  sleep 5
  echo "🔄 cloud-init..."
done
echo "✅ cloud-init finalizado!"

# ===============================
# Setup Base (Ansible)
# ===============================
echo "⚙️ [1/4] Setup base..."
ansible-playbook -i "$IP," ansible-ec2-n8n/playbook_setup.yml \
  --private-key $KEY \
  -u $USER \
  -e 'ansible_ssh_common_args="-o StrictHostKeyChecking=no"'

# ===============================
# Containers (n8n + PostgreSQL)
# ===============================
echo "🐳 [2/4] Containers..."
ansible-playbook -i "$IP," ansible-ec2-n8n/playbook_containers.yml \
  --private-key $KEY \
  -u $USER \
  -e 'ansible_ssh_common_args="-o StrictHostKeyChecking=no"'

# ===============================
# Loop DNS inteligente
# ===============================
echo "⏳ Verificando se $DOMINIO aponta para $IP..."

for i in {1..30}; do
  IP_RESOLVIDO=$(dig +short $DOMINIO | tail -n1)
  if [ "$IP_RESOLVIDO" = "$IP" ]; then
    echo "✅ DNS propagado corretamente: $DOMINIO → $IP"
    break
  fi
  echo "🔄 DNS ainda não aponta para $IP ($i/30)"
  sleep 10
done

IP_RESOLVIDO=$(dig +short $DOMINIO | tail -n1)
if [ "$IP_RESOLVIDO" != "$IP" ]; then
  echo "⚠️ ATENÇÃO: $DOMINIO ainda não aponta para $IP"
  echo "👉 Atualize o A record no Hostinger antes de continuar."
  exit 1
fi

# ===============================
# Nginx
# ===============================
echo "🌐 [3/4] Nginx..."
ansible-playbook -i "$IP," ansible-ec2-n8n/playbook_nginx.yml \
  --private-key $KEY \
  -u $USER \
  -e 'ansible_ssh_common_args="-o StrictHostKeyChecking=no"'

# ===============================
# SSL com Certbot
# ===============================
echo "🔒 [4/4] SSL..."
ansible-playbook -i "$IP," ansible-ec2-n8n/playbook_nginx.yml \
  --private-key $KEY \
  -u $USER \
  -e 'ansible_ssh_common_args="-o StrictHostKeyChecking=no" enable_ssl=true'

# ===============================
# Validação HTTP/HTTPS
# ===============================
echo "🧪 Validando aplicação..."

if curl -s -o /dev/null -w "%{http_code}" http://$IP | grep -q 200; then
  echo "✅ HTTP OK"
else
  echo "❌ HTTP falhou"
fi

if curl -k -s -o /dev/null -w "%{http_code}" https://$DOMINIO | grep -q 200; then
  echo "✅ HTTPS OK"
else
  echo "❌ HTTPS falhou"
fi

echo "✅ Deploy finalizado!"
echo "🌐 http://$IP"
echo "🔒 https://$DOMINIO"