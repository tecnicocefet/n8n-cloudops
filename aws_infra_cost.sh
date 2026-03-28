#!/bin/bash
# aws_infra_cost_from_csv.sh
# Calcula custo mensal aproximado a partir do CSV exportado

CSV_FILE="aws_infra.csv"

EC2_COST=0
EBS_COST=0
EIP_COST=0

while IFS=',' read -r RESOURCE ID TYPE_AZ SIZE STATE ASSOCIATED
do
  # Pular o header
  if [ "$RESOURCE" == "Resource" ]; then
    continue
  fi

  case "$RESOURCE" in
    EC2)
      # t3.micro ~$8/mês, ajuste conforme tipo
      if [ "$TYPE_AZ" == "t3.micro" ]; then
        EC2_COST=$(echo "$EC2_COST + 8" | bc)
      else
        # estimativa genérica: $10/mês para outros tipos pequenos
        EC2_COST=$(echo "$EC2_COST + 10" | bc)
      fi
      ;;
    EBS)
      # extrair número antes do GB
      GB=$(echo $TYPE_AZ | grep -oE '[0-9]+')
      EBS_COST=$(echo "$EBS_COST + $GB * 0.08" | bc)
      ;;
    EIP)
      if [ "$ASSOCIATED" == "No" ]; then
        EIP_COST=$(echo "$EIP_COST + 3.6" | bc)
      fi
      ;;
  esac
done < "$CSV_FILE"

TOTAL_COST=$(echo "$EC2_COST + $EBS_COST + $EIP_COST" | bc)

echo "===== Estimativa de custo mensal aproximado ====="
echo "EC2: $EC2_COST USD"
echo "EBS: $EBS_COST USD"
echo "Elastic IP (não associado): $EIP_COST USD"
echo "-----------------------------------------------"
echo "Total aproximado: $TOTAL_COST USD/mês"