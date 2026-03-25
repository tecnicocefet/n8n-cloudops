#!/bin/bash

echo "⚠️ ATENÇÃO: Isso vai destruir toda a infraestrutura criada!"

read -p "Tem certeza? (yes/no): " confirm

if [ "$confirm" != "yes" ]; then
  echo "❌ Cancelado."
  exit 1
fi

echo "💣 Destruindo infraestrutura..."

terraform -chdir=terraform_ec2 destroy -auto-approve

echo "🧹 Infra destruída com sucesso!"