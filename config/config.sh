#!/bin/bash

# C.A.L.M.A. - Configurações do Sistema
# Este script carrega as variáveis de ambiente do arquivo .env

BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ENV_FILE="${BASE_DIR}/.env"

# Verificar se o arquivo .env existe
if [ ! -f "$ENV_FILE" ]; then
    echo "❌ Arquivo .env não encontrado!"
    echo ""
    echo "Para configurar o sistema:"
    echo "  1. Copie o arquivo de exemplo: cp .env.example .env"
    echo "  2. Edite o arquivo .env com as suas credenciais"
    echo "  3. Ou execute: ./setup.sh"
    exit 1
fi

# Carregar variáveis do arquivo .env
set -o allexport
source "$ENV_FILE"
set +o allexport

# Verificar variáveis essenciais
if [ -z "$EMAIL_USER" ] || [ "$EMAIL_USER" = "seu_email@gmail.com" ]; then
    echo "❌ Configure o EMAIL_USER no arquivo .env"
    exit 1
fi

if [ -z "$EMAIL_PASS" ] || [ "$EMAIL_PASS" = "xxxx xxxx xxxx xxxx" ]; then
    echo "❌ Configure o EMAIL_PASS no arquivo .env"
    exit 1
fi

# Exportar diretórios
export BASE_DIR
export CONFIG_DIR="${BASE_DIR}/config"
export DATA_DIR="${BASE_DIR}/data"
export LOGS_DIR="${BASE_DIR}/logs"
export EMAIL_ATTACHMENTS_DIR="${DATA_DIR}/anexos_processados"
export PENDING_DIR="${EMAIL_ATTACHMENTS_DIR}/pending"
export CLEAN_DIR="${EMAIL_ATTACHMENTS_DIR}/clean"
export INFECTED_DIR="${EMAIL_ATTACHMENTS_DIR}/infected"
export QUARANTINE_DIR="${DATA_DIR}/quarantine"

export LOG_LEVEL="INFO"  # DEBUG, INFO, WARN, ERROR
export KEEP_LOGS_DAYS="7"

export HASH_ALGORITHM="sha256"
export ENABLE_METADATA="true"

echo "Configurações carregadas. Execute './calma.sh' para iniciar."
