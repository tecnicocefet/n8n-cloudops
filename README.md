# n8n‑CloudOps — Infraestrutura Self‑Hosted de Automação

Este projeto implementa uma **infraestrutura de automações robusta e persistente** para execução de workflows no **n8n**, com banco de dados **PostgreSQL**, integração com serviços externos (como **Twilio**) e deploy automatizado via **Terraform**, **Ansible** e **Docker Compose**.

O objetivo é permitir que equipes técnicas provisionem, configurem e operem **workflows automáticos** de forma confiável e repetível, sem intervenção manual em servidores ou containers.

---

## 🚀 Tecnologias Envolvidas

Este projeto utiliza:

| Camada | Tecnologia |
| -------- | ------------ |
| Infraestrutura na nuvem | Terraform |
| Provisionamento de servidores | AWS EC2 + EBS |
| Automação de configuração | Ansible |
| Containers | Docker & Docker Compose |
| Banco de dados | PostgreSQL |
| Workflow automation | n8n |
| Integração de APIs e mensagens | Twilio |
| Scripts auxiliares | Bash |
| Variáveis secretas | Arquivos criptografados |

**Propósito:** criar uma infraestrutura confiável para criar automações e workflows que persistem dados mesmo após reinicializações.

---

## 📁 Estrutura do Repositório

── ansible-ec2-n8n/ # Playbooks Ansible para configuração
├── terraform_ec2/ # Provisionamento AWS (EC2 + EBS)
├── vars/ # Segredos com credenciais e chaves
├── aws_infra.csv # Export de custos da AWS
├── aws_infra_cost.sh # Script de análise de custos
├── deploy.sh # Script para deploy completo
├── destroy.sh # Script para destruir infra
├── ec2_manage.sh # Script de gerenciamento de instância
└── README.md # Este arquivo


---

## 📦 Pré‑requisitos

Antes de rodar o deploy:

✔️ Chave SSH configurada para o host EC2  
✔️ **Terraform** instalado localmente  
✔️ **Ansible** instalado localmente  
✔️ Acesso à AWS configurado (credenciais/SSO)  
✔️ Arquivo de variáveis secreto (`vars/secrets.yml`)  

---

## 📌 Como Usar

### 1️⃣ Provisionar infraestrutura

```bash
./deploy.sh

Este script:

Executa terraform init e terraform apply
Espera a EC2 ficar acessível
Roda Ansible para configurar Docker e subir n8n + PostgreSQL
Configura SSL e NGINX (se aplicável)
Retorna IP e URLs acessíveis
2️⃣ Gerenciar instância
Parar/ligar EC2: ./ec2_manage.sh
Destruir toda infraestrutura: ./destroy.sh
🛠️ Como Funciona o Deploy

O processo é dividido em camadas:

Terraform
Provisiona EC2 (Ubuntu)
Cria e anexa EBS para persistência de dados
Expõe IP fixo, grupos de segurança e outputs úteis
Ansible
Instala Docker e Docker Compose
Garante montagem de EBS em /data
Cria diretórios persistentes:
/data/postgres-data
/data/n8n-data
Sobe containers:
PostgreSQL (persistente)
n8n (persistente com volume)
Usa healthcheck para garantir dependências
Bash Helpers

Scripts auxiliares como aws_infra_cost.sh ajudam no controle de custos, análises e manutenção da infraestrutura.

🧠 Propósito da Infraestrutura

Esta infraestrutura é pensada para criar, testar e operar automações, como:

Integrações com API (ex: Twilio, Stripe, Slack)
Webhooks e triggers
Agentes inteligentes conectados a workflows
Processamento de eventos em tempo real

O foco é permitir automação persistente, escalável e confiável.

🧪 Workflow com Twilio (Próximo Passo)

Você pode criar automações no n8n que:

Recebem dados via webhook
Processam lógica de negócios
Enviam SMS | WhatsApp através da Twilio API

A integração com Twilio requer que você crie credenciais no painel do Twilio e as configure no n8n.

📜 Histórico de Commits

fix: implementar persistência n8n + PostgreSQL via EBS
feat: adicionar integração inicial com Twilio

📚 Referências
🔗 n8n — workflow automation platform
🐘 PostgreSQL — banco relacional robusto
🐋 Docker & Compose — containerização
🎯 AWS EBS & EC2 — infraestrutura elástica na nuvem