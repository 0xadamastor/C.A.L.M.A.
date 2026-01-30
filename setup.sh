#!/bin/bash

# C.A.L.M.A. - Setup Script
# Este script configura o sistema pedindo as credenciais interativamente

set -e

# Cores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Banner
echo -e "${BLUE}"
echo "┌─────────────────────────────────────────────────────────────┐"
echo "│                    C.A.L.M.A. Setup                        │"
echo "│          Configuração Segura do Sistema                    │"
echo "└─────────────────────────────────────────────────────────────┘"
echo -e "${NC}"

BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ENV_FILE="${BASE_DIR}/.env"

# Input seguro (password)
secure_input() {
    local prompt="$1"
    echo -n -e "${YELLOW}${prompt}: ${NC}"
    read -s value
    echo
    echo "$value"
}

# Input normal com default
normal_input() {
    local prompt="$1"
    local default="$2"
    if [ -n "$default" ]; then
        echo -n -e "${YELLOW}${prompt} [${default}]: ${NC}"
    else
        echo -n -e "${YELLOW}${prompt}: ${NC}"
    fi
    read value
    echo "${value:-$default}"
}

echo -e "${GREEN}Vamos configurar o C.A.L.M.A.${NC}"
echo

# Configurações de Email
echo -e "${BLUE}📧 Configurações de Email${NC}"
echo "─────────────────────────"
EMAIL_USER=$(normal_input "Email")
EMAIL_PASS=$(secure_input "Password/App Password")
EMAIL_SERVER=$(normal_input "Servidor IMAP" "imap.gmail.com")
EMAIL_PORT=$(normal_input "Porta IMAP" "993")
echo

# Sandbox (opcional)
echo -e "${BLUE}🛡️  Sandbox (opcional)${NC}"
echo "──────────────────────"
SANDBOX_ENABLED=$(normal_input "Ativar sandbox? (true/false)" "false")
if [ "$SANDBOX_ENABLED" = "true" ]; then
    SANDBOX_URL=$(normal_input "URL do Sandbox" "http://localhost:8090")
    SANDBOX_API_KEY=$(secure_input "API Key do Sandbox")
else
    SANDBOX_URL="http://localhost:8090"
    SANDBOX_API_KEY=""
fi
echo

# Configurações de segurança
echo -e "${BLUE}🔐 Configurações de Segurança${NC}"
echo "──────────────────────────────"
MAX_FILE_SIZE=$(normal_input "Tamanho máximo de arquivo (bytes)" "10485760")
SCAN_TIMEOUT=$(normal_input "Timeout de scan (segundos)" "300")
MIN_MALICIOUS_SCORE=$(normal_input "Score mínimo para malicioso" "70")
SUSPICIOUS_SCORE_RANGE=$(normal_input "Range de score suspeito" "30-69")
echo

# Gerar chave Flask
echo -e "${BLUE}🔑 Gerando chave secreta...${NC}"
FLASK_SECRET_KEY=$(python3 -c "import secrets; print(secrets.token_hex(32))" 2>/dev/null || echo "calma-secret-$(date +%s)")

# Criar diretórios
echo -e "${GREEN}📁 Criando diretórios...${NC}"
mkdir -p "${BASE_DIR}/data"/{anexos_processados,quarentena,relatorios}
mkdir -p "${BASE_DIR}/data/anexos_processados"/{a_analisar,limpos,infetados}
mkdir -p "${BASE_DIR}/logs"

# Criar .env
echo -e "${GREEN}📝 Criando arquivo .env...${NC}"
cat > "$ENV_FILE" << EOF
# C.A.L.M.A. - Configurações
# Gerado em $(date)

# Email
EMAIL_USER=${EMAIL_USER}
EMAIL_PASS=${EMAIL_PASS}
EMAIL_SERVER=${EMAIL_SERVER}
EMAIL_PORT=${EMAIL_PORT}

# Sandbox
SANDBOX_ENABLED=${SANDBOX_ENABLED}
SANDBOX_URL=${SANDBOX_URL}
SANDBOX_API_KEY=${SANDBOX_API_KEY}

# Segurança
MAX_FILE_SIZE=${MAX_FILE_SIZE}
SCAN_TIMEOUT=${SCAN_TIMEOUT}
MIN_MALICIOUS_SCORE=${MIN_MALICIOUS_SCORE}
SUSPICIOUS_SCORE_RANGE=${SUSPICIOUS_SCORE_RANGE}

# Flask
FLASK_SECRET_KEY=${FLASK_SECRET_KEY}
EOF

chmod 600 "$ENV_FILE"

# Ambiente virtual Python
echo -e "${GREEN}🐍 Configurando ambiente Python...${NC}"
if [ ! -d "${BASE_DIR}/venv" ]; then
    python3 -m venv "${BASE_DIR}/venv"
fi
source "${BASE_DIR}/venv/bin/activate"
pip install -q -r "${BASE_DIR}/requirements.txt"

echo
echo -e "${GREEN}✅ Setup concluído!${NC}"
echo
echo -e "${BLUE}Resumo:${NC}"
echo "  • Email: $EMAIL_USER"
echo "  • Servidor: $EMAIL_SERVER:$EMAIL_PORT"
echo "  • Sandbox: $SANDBOX_ENABLED"
echo "  • Configuração: .env (permissões 600)"
echo
echo -e "${GREEN}Para executar:${NC}"
echo "  ./calma.sh              # Análise de anexos"
echo "  ./start.sh              # Menu interativo"
echo "  source venv/bin/activate && python config/app.py  # Interface web"