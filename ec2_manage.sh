#!/bin/bash
set -e

# ===============================
# CONFIGURAÇÕES
# ===============================
REGION="us-east-1"
INSTANCE_NAME="n8n-demo"

# ===============================
# FUNÇÃO PARA EXECUTAR COM RETRY AWS SSO
# ===============================
aws_cmd_retry() {
    CMD="$1"
    OUTPUT=$($CMD 2>&1) || true

    if echo "$OUTPUT" | grep -q -E "ExpiredToken|UnrecognizedClientException"; then
        echo "⚠️ Credenciais AWS inválidas ou expiradas. Abrindo login SSO..."
        aws sso login --region $REGION
        echo "🔄 Tentando novamente..."
        OUTPUT=$($CMD 2>&1) || { echo "❌ Erro após login SSO: $OUTPUT"; exit 1; }
    fi

    echo "$OUTPUT"
}

# ===============================
# PEGAR ID DA EC2
# ===============================
EC2_ID=$(aws ec2 describe-instances \
    --filters Name=tag:Name,Values=$INSTANCE_NAME Name=instance-state-name,Values=running,stopped \
    --query "Reservations[0].Instances[0].InstanceId" \
    --output text \
    --region $REGION)

if [[ -z "$EC2_ID" || "$EC2_ID" == "None" ]]; then
    echo "❌ Nenhuma instância encontrada com a tag Name=$INSTANCE_NAME"
    exit 1
fi

echo "✅ Instância encontrada: $EC2_ID"

# ===============================
# PEGAR STATUS DA EC2
# ===============================
get_ec2_status() {
    STATUS=$(aws_cmd_retry "aws ec2 describe-instances \
        --instance-ids $EC2_ID \
        --region $REGION \
        --query Reservations[0].Instances[0].State.Name \
        --output text")
    echo "$STATUS"
}

# ===============================
# SCRIPT PRINCIPAL
# ===============================
STATUS=$(get_ec2_status)
echo "💻 Status atual da EC2: $STATUS"

read -p "Deseja ligar, desligar ou continuar com a EC2? (ligar/desligar/continuar) " ACTION

if [[ "$ACTION" == "ligar" ]]; then
    if [[ "$STATUS" == "running" ]]; then
        echo "✅ A EC2 já está ligada."
    else
        echo "🔌 Ligando EC2..."
        aws_cmd_retry "aws ec2 start-instances --instance-ids $EC2_ID --region $REGION" >/dev/null
        echo "⏳ Aguardando EC2 ficar ativa..."
        until [[ "$(get_ec2_status)" == "running" ]]; do
            sleep 5
            echo "🔄 Esperando..."
        done
        echo "✅ EC2 ligada!"
    fi
elif [[ "$ACTION" == "desligar" ]]; then
    if [[ "$STATUS" == "stopped" ]]; then
        echo "✅ A EC2 já está desligada."
        exit 0
    else
        echo "🔌 Desligando EC2..."
        aws_cmd_retry "aws ec2 stop-instances --instance-ids $EC2_ID --region $REGION" >/dev/null
        echo "⏳ Aguardando EC2 desligar..."
        until [[ "$(get_ec2_status)" == "stopped" ]]; do
            sleep 5
            echo "🔄 Esperando..."
        done
        echo "✅ EC2 desligada!"
        exit 0
    fi
elif [[ "$ACTION" == "continuar" ]]; then
    echo "➡️ Continuando sem ligar/desligar a EC2..."
else
    echo "❌ Opção inválida. Use 'ligar', 'desligar' ou 'continuar'."
    exit 1
fi

# ===============================
# Mostrar IP público
# ===============================
EC2_IP=$(aws_cmd_retry "aws ec2 describe-instances --instance-ids $EC2_ID --region $REGION --query Reservations[0].Instances[0].PublicIpAddress --output text")
echo "🌐 IP público da EC2: $EC2_IP"