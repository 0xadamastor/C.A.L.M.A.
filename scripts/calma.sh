#!/bin/bash

# ============================================
# CALMA - Classificador Automático de Links e Malware em Anexo
# ============================================

CALMA_HOME="/opt/calma"
LOG_DIR="${CALMA_HOME}/logs"
INCOMING_DIR="${CALMA_HOME}/incoming"
ATTACHMENTS_DIR="${CALMA_HOME}/attachments"
REPORTS_DIR="${CALMA_HOME}/reports"
QUARANTINE_DIR="${CALMA_HOME}/quarantine"
DB_FILE="${CALMA_HOME}/calma.db"
FORENSIC_LOG="${LOG_DIR}/forensic/calma_forensic.csv"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_message() {
    local level=$1
    local message=$2Classificador Automático de Links e Malware em Anexo
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo -e "[${timestamp}] [${level}] ${message}"
    echo "[${timestamp}] [${level}] ${message}" >> "${LOG_DIR}/system/calma_system.log"
}

fetch_emails() {
    log_message "INFO" "Baixando emails da caixa de entrada..."

    local fetchmail_conf="${CALMA_HOME}/config/fetchmailrc"

    if [ ! -f "$fetchmail_conf" ]; then
        log_message "ERROR" "Arquivo fetchmailrc não encontrado em ${fetchmail_conf}"
        return 1
    fi

    fetchmail --fetchmailrc "$fetchmail_conf" --silent

    if [ -d "$INCOMING_DIR" ]; then
        for email_file in "$INCOMING_DIR"/*; do
            if [ -f "$email_file" ]; then
                munpack -f -q -C "$ATTACHMENTS_DIR" "$email_file" 2>/dev/null
                log_message "DEBUG" "Extraído anexos de $(basename "$email_file")"
            fi
        done
    fi

    local attachment_count=$(find "${ATTACHMENTS_DIR}" -type f 2>/dev/null | wc -l)
    log_message "INFO" "Encontrados ${attachment_count} anexos"

    return $attachment_count
}

calculate_hash() {
    local file_path=$1
    sha256sum "$file_path" | awk '{print $1}'
}

analyze_file() {
    local file_path=$1
    local file_name=$(basename "$file_path")
    local score=0

    log_message "INFO" "Analisando arquivo: ${file_name}"

    local file_type=$(file -b "$file_path")
    log_message "DEBUG" "Tipo do arquivo: ${file_type}"

    if command -v clamscan &> /dev/null; then
        local clam_result=$(clamscan --no-summary "$file_path" 2>/dev/null)
        if echo "$clam_result" | grep -q "FOUND"; then
            log_message "WARNING" "ClamAV detectou ameaça em ${file_name}"
            score=$((score + 80))
        fi
    fi

    local extension="${file_name##*.}"
    case "$extension" in
        exe|dll|vbs|js|bat|ps1|scr)
            log_message "WARNING" "Extensão suspeita: .${extension}"
            score=$((score + 20))
            ;;
        pdf|doc|docx|xls|xlsx)
            score=$((score + 10))
            ;;
    esac

    local file_size=$(stat -c%s "$file_path")
    if [ $file_size -lt 100 ]; then
        score=$((score + 15))
    fi

    if command -v strings &> /dev/null; then
        local suspicious_strings=$(strings "$file_path" | grep -i -c -E "(malware|virus|trojan|exploit|payload|shellcode)")
        if [ $suspicious_strings -gt 0 ]; then
            score=$((score + suspicious_strings * 5))
        fi
    fi

    if [ $score -gt 100 ]; then
        score=100
    fi

    echo $score
}

classify_file() {
    local score=$1
    local threshold=40

    if [ "$score" -ge "$threshold" ]; then
        echo "INFECTED"
    else
        echo "CLEAN"
    fi
}

move_email_imap() {
    local message_id=$1
    local classification=$2

    local imap_config="${CALMA_HOME}/config/imapfilter_config.lua"

    if [ ! -f "$imap_config" ]; then
        log_message "ERROR" "Configuração IMAPFilter não encontrada"
        return 1
    fi

    local temp_script="/tmp/calma_imap_$$.lua"

    cat > "$temp_script" << EOF
-- Script para mover email do CALMA
dofile("${imap_config}")

-- Procurar email pelo Message-ID
local results = inbox:contain_field('Message-ID', '${message_id}')

if #results > 0 then
    if '${classification}' == 'INFECTED' then
        results:move_messages(infected_folder)
        print('CALMA: Movido ${message_id} para pasta Infected')
    else
        results:move_messages(clean_folder)
        print('CALSA: Movido ${message_id} para pasta Clean')
    end
    print('Sucesso')
else
    print('CALMA: Email com Message-ID ${message_id} não encontrado')
end
EOF

    local result=$(imapfilter -c "$temp_script" 2>/dev/null)

    if echo "$result" | grep -q "Sucesso"; then
        log_message "SUCCESS" "Email movido para pasta ${classification}"
        rm -f "$temp_script"
        return 0
    else
        log_message "WARNING" "Não foi possível mover o email: $result"
        rm -f "$temp_script"
        return 1
    fi
}

log_forensic() {
    local timestamp=$1
    local filename=$2
    local hash=$3
    local score=$4
    local classification=$5
    local message_id=$6

    mkdir -p "$(dirname "$FORENSIC_LOG")"

    if [ ! -f "$FORENSIC_LOG" ]; then
        echo "timestamp,filename,sha256,score,classification,message_id" > "$FORENSIC_LOG"
    fi

    echo "${timestamp},${filename},${hash},${score},${classification},${message_id}" >> "$FORENSIC_LOG"

    log_message "INFO" "Registro forense criado para ${filename}"
}

process_attachment() {
    local file_path=$1
    local message_id=$2
    local file_name=$(basename "$file_path")

    log_message "INFO" "=== Processando: ${file_name} ==="

    local file_hash=$(calculate_hash "$file_path")
    log_message "DEBUG" "SHA256: ${file_hash}"

    if [ -f "$FORENSIC_LOG" ] && grep -q "$file_hash" "$FORENSIC_LOG" 2>/dev/null; then
        log_message "INFO" "Arquivo já analisado anteriormente"
        return 0
    fi

    local score=$(analyze_file "$file_path")
    local classification=$(classify_file "$score")

    log_message "RESULT" "Arquivo: ${file_name} | Score: ${score}/100 | Classificação: ${classification}"

    move_email_imap "$message_id" "$classification"

    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    log_forensic "$timestamp" "$file_name" "$file_hash" "$score" "$classification" "$message_id"

    if [ "$classification" = "INFECTED" ]; then
        local quarantine_path="${QUARANTINE_DIR}/${file_hash}_${file_name}"
        mv "$file_path" "$quarantine_path"
        log_message "WARNING" "Arquivo movido para quarentena: ${quarantine_path}"
    else
        mv "$file_path" "${ATTACHMENTS_DIR}/clean/"
        log_message "INFO" "Arquivo movido para pasta clean"
    fi

    log_message "SUCCESS" "Processamento concluído para ${file_name}"
    return 0
}

main() {
    log_message "INFO" "=== INICIANDO CALMA ==="

    mkdir -p "${INCOMING_DIR}" "${ATTACHMENTS_DIR}" "${ATTACHMENTS_DIR}/clean"
    mkdir -p "${REPORTS_DIR}" "${QUARANTINE_DIR}"
    mkdir -p "${LOG_DIR}/forensic" "${LOG_DIR}/analysis" "${LOG_DIR}/system"

    log_message "INFO" "Passo 1: Baixando emails..."
    fetch_emails
    local email_count=$?

    if [ $email_count -eq 0 ]; then
        log_message "INFO" "Nenhum novo email encontrado"
    fi

    log_message "INFO" "Passo 2: Processando anexos..."
    local processed_count=0

    local batch_id="calma_$(date +%Y%m%d_%H%M%S)"

    find "${ATTACHMENTS_DIR}" -maxdepth 1 -type f | while read -r file; do
        [ -d "$file" ] && continue

        local file_name=$(basename "$file")

        local message_id="${batch_id}_${file_name%.*}_$(date +%s)@calma.local"

        if process_attachment "$file" "$message_id"; then
            processed_count=$((processed_count + 1))
        fi

        sleep 1
    done

    rm -f "${INCOMING_DIR}"/* 2>/dev/null

    log_message "INFO" "Processamento concluído. ${processed_count} arquivos analisados."
    log_message "INFO" "=== CALMA FINALIZADO ==="

    return 0
}

main "$@"
