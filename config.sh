#!/bin/bash

export EMAIL_USER="email@gmail.com"
export EMAIL_PASS="xxxx xxxx xxxx xxxx"
export EMAIL_SERVER="imap.gmail.com"
export EMAIL_PORT="993"

export SANDBOX_ENABLED="false"
export SANDBOX_URL="http://localhost:8090"
export SANDBOX_API_KEY=""

export MAX_FILE_SIZE="10485760"  # 10MB em bytes
export SCAN_TIMEOUT="300"        # 5 minutos
export MIN_MALICIOUS_SCORE="70"  # Score mínimo para considerar infetado
export SUSPICIOUS_SCORE_RANGE="30-69"  # Intervalo para suspeitos

export BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export LOGS_DIR="${BASE_DIR}/logs"
export DATA_DIR="${BASE_DIR}/data"
export EMAIL_ATTACHMENTS_DIR="${DATA_DIR}/email_attachments"
export PENDING_DIR="${EMAIL_ATTACHMENTS_DIR}/pending"
export CLEAN_DIR="${EMAIL_ATTACHMENTS_DIR}/clean"
export INFECTED_DIR="${EMAIL_ATTACHMENTS_DIR}/infected"
export QUARANTINE_DIR="${DATA_DIR}/quarantine"

export LOG_LEVEL="INFO"  # DEBUG, INFO, WARN, ERROR
export KEEP_LOGS_DAYS="7"

export HASH_ALGORITHM="sha256"
export ENABLE_METADATA="true"

echo "Configurações carregadas. Execute './calma.sh' para iniciar."
