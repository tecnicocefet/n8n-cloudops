#!/bin/bash
set -e

# Caminhos Base (Usando pwd para garantir caminhos absolutos)
ROOT_DIR=$(pwd)
KEY=~/.ssh/funnel_hub.pem
USER=ubuntu
VAULT_PASS=$ROOT_DIR/.vault_pass
SECRETS=$ROOT_DIR/vars/secrets.yml

echo "🚀 Subindo infraestrutura com Terraform..."
terraform -chdir=terraform_ec2 init
terraform -chdir=terraform_ec2 apply -auto-approve

# Captura Outputs do Terraform
IP=$(terraform -chdir=terraform_ec2 output -raw public_ip)
URL=$(terraform -chdir=terraform_ec2 output -raw n8n_url)

echo "🌐 IP Alocado: $IP"
echo "🔗 Domínio: $URL"

echo "⏳ Aguardando conexão SSH ficar disponível..."
until ssh -i "$KEY" -o StrictHostKeyChecking=no -o ConnectTimeout=5 "$USER@$IP" "echo ok" >/dev/null 2>&1; do
  sleep 5
done
echo "✅ SSH pronto!"

# ---------------- Setup + Containers ---------------- #
echo "⚙️ Executando Playbook de Containers (Docker + EBS + n8n)..."
# O @ na frente do caminho dos segredos é o segredo para o Ansible carregar o Vault corretamente
ansible-playbook -i "$IP," "$ROOT_DIR/ansible-ec2-n8n/playbook_setup_containers.yml" \
  --private-key "$KEY" \
  --vault-password-file "$VAULT_PASS" \
  -e "@$SECRETS" \
  -u "$USER" \
  -e 'ansible_ssh_common_args="-o StrictHostKeyChecking=no"' \
  --diff

# ---------------- Nginx ---------------- #
echo "🌐 Configurando Nginx e Proxy Reverso..."
ansible-playbook -i "$IP," "$ROOT_DIR/ansible-ec2-n8n/playbook_nginx.yml" \
  --private-key "$KEY" \
  --vault-password-file "$VAULT_PASS" \
  -e "@$SECRETS" \
  -u "$USER" \
  -e 'ansible_ssh_common_args="-o StrictHostKeyChecking=no"'

# ---------------- SSL (Opcional se já estiver no Playbook Nginx) ---------------- #
echo "🔒 Garantindo configurações de SSL..."
ansible-playbook -i "$IP," "$ROOT_DIR/ansible-ec2-n8n/playbook_nginx.yml" \
  --private-key "$KEY" \
  --vault-password-file "$VAULT_PASS" \
  -e "@$SECRETS" \
  -u "$USER" \
  -e 'ansible_ssh_common_args="-o StrictHostKeyChecking=no" enable_ssl=true'

echo "🧪 Testando resposta dos endpoints..."
echo "--- Teste via IP ---"
curl -I "http://$IP" || true
echo "--- Teste via Domínio ---"
curl -k -I "$URL" || true

echo "✅ Deploy finalizado com sucesso!"
echo "👉 Painel n8n: $URL"