#!/bin/bash

# ============================================
# C.A.L.M.A
# ============================================

CALMA_HOME="/opt/calma"
LOG_DIR="${CALMA_HOME}/logs"
INCOMING_DIR="${CALMA_HOME}/incoming"
ATTACHMENTS_DIR="${CALMA_HOME}/attachments"
REPORTS_DIR="${CALMA_HOME}/reports"
QUARANTINE_DIR="${CALMA_HOME}/quarantine"
FORENSIC_LOG="${LOG_DIR}/forensic/calma_forensic.csv"
DB_FILE="${CALMA_HOME}/calma.db"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_message() {
    local level=$1
    local message=$2
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo -e "[${timestamp}] [${level}] ${message}"
    echo "[${timestamp}] [${level}] ${message}" >> "${LOG_DIR}/system/calma_system.log"
}

fetch_new_emails() {
    log_message "INFO" "Verificando novos emails..."

    local fetchmail_conf="${CALMA_HOME}/config/fetchmailrc"

    if [ ! -f "$fetchmail_conf" ]; then
        log_message "ERROR" "Arquivo fetchmailrc não encontrado!"
        return 1
    fi

    # Baixar apenas emails não lidos (--nokeep para remover após download)
    fetchmail --fetchmailrc "$fetchmail_conf" --nokeep --silent

    local new_emails=$(ls -1 "$INCOMING_DIR"/*.email 2>/dev/null | wc -l)
    log_message "INFO" "Baixados ${new_emails} novos emails"

    return $new_emails
}

# Extrair Message-ID do email
extract_message_info() {
    local email_file=$1
    local message_id=""
    local subject=""
    local from=""

    message_id=$(grep -i "^Message-ID:" "$email_file" | head -1 | \
                sed 's/^Message-ID:\s*//i' | tr -d '<>' | tr -d '[:space:]')

    subject=$(grep -i "^Subject:" "$email_file" | head -1 | \
             sed 's/^Subject:\s*//i' | cut -c1-50)

    from=$(grep -i "^From:" "$email_file" | head -1 | \
           sed 's/^From:\s*//i' | cut -c1-50)

    if [ -z "$message_id" ]; then
        message_id="calma_$(date +%s)_$(basename "$email_file" .email | md5sum | cut -c1-8)@calma.local"
    fi

    echo "$message_id|$subject|$from"
}

extract_attachments() {
    local email_file=$1
    local output_dir="$ATTACHMENTS_DIR/$(date +%Y%m%d_%H%M%S)"

    mkdir -p "$output_dir"

    munpack -f -q -C "$output_dir" "$email_file" 2>/dev/null

    local attachments=$(find "$output_dir" -type f 2>/dev/null | wc -l)

    if [ $attachments -gt 0 ]; then
        echo "$output_dir"
        log_message "INFO" "Extraídos ${attachments} anexos de $(basename "$email_file")"
    else
        rmdir "$output_dir" 2>/dev/null
        echo ""
    fi
}

analyze_file() {
    local file_path=$1
    local file_name=$(basename "$file_path")
    local score=0

    log_message "INFO" "Analisando: $file_name"

    local file_type=$(file -b "$file_path")
    log_message "DEBUG" "Tipo: $file_type"

    local extension="${file_name##*.}"
    local ext_lower=$(echo "$extension" | tr '[:upper:]' '[:lower:]')

    case "$ext_lower" in
        exe|dll|vbs|js|bat|ps1|scr|jar|wsf|hta)
            score=$((score + 40))
            log_message "WARNING" "Extensão potencialmente perigosa: .$ext_lower"
            ;;
        pdf|doc|docx|xls|xlsx|ppt|pptx|rtf)
            score=$((score + 20))
            log_message "INFO" "Documento Office/PDF: .$ext_lower"
            ;;
        zip|rar|7z|tar|gz)
            score=$((score + 10))
            log_message "INFO" "Arquivo compactado: .$ext_lower"
            ;;
    esac

    if command -v clamscan &> /dev/null; then
        local clam_result=$(clamscan --no-summary "$file_path" 2>/dev/null)
        if echo "$clam_result" | grep -q "FOUND"; then
            score=$((score + 60))
            local virus_name=$(echo "$clam_result" | grep -o "FOUND" | head -1)
            log_message "ALERT" "ClamAV detectou: $virus_name"
        fi
    fi

    if command -v strings &> /dev/null && [ $score -lt 80 ]; then
        local sus_strings=$(strings "$file_path" | grep -i -c -E \
            "(malware|virus|trojan|exploit|shellcode|keylogger|ransomware|backdoor)")

        if [ $sus_strings -gt 0 ]; then
            score=$((score + sus_strings * 5))
            log_message "WARNING" "Encontradas $sus_strings strings suspeitas"
        fi
    fi

    local file_size=$(stat -c%s "$file_path" 2>/dev/null || echo "0")

    if [ $file_size -lt 100 ] || [ $file_size -gt 10485760 ]; then
        score=$((score + 10))
        log_message "INFO" "Tamanho atípico: ${file_size} bytes"
    fi

    [ $score -gt 100 ] && score=100

    echo $score
}

move_email() {
    local message_id=$1
    local classification=$2
    local subject=$3

    local imap_config="${CALMA_HOME}/config/imapfilter_config.lua"
    local temp_script="/tmp/calma_move_$$.lua"

    cat > "$temp_script" << EOF
dofile("${imap_config}")

-- Procurar email pelo Message-ID
local results = inbox:search('HEADER "Message-ID" "${message_id}"')

if #results > 0 then
    -- Marcar como lido
    inbox:mark_flagged(results)

    -- Mover para pasta apropriada
    if '${classification}' == 'INFECTED' then
        results:move_messages(infected_folder)
        print("SUCCESS: Email movido para Infected - ${subject}")
    else
        results:move_messages(clean_folder)
        print("SUCCESS: Email movido para Clean - ${subject}")
    end
else
    print("ERROR: Email não encontrado - Message-ID: ${message_id}")
end
EOF

    local result=$(imapfilter -c "$temp_script" 2>/dev/null)

    if echo "$result" | grep -q "SUCCESS"; then
        log_message "SUCCESS" "Email movido para pasta $classification"
        rm -f "$temp_script"
        return 0
    else
        log_message "WARNING" "Falha ao mover email: $result"
        rm -f "$temp_script"
        return 1
    fi
}

process_email() {
    local email_file="$1"
    local email_name=$(basename "$email_file")

    log_message "INFO" "Processando email: $email_name"

    local email_info=$(extract_message_info "$email_file")
    local message_id=$(echo "$email_info" | cut -d'|' -f1)
    local subject=$(echo "$email_info" | cut -d'|' -f2)
    local from=$(echo "$email_info" | cut -d'|' -f3)

    log_message "INFO" "De: $from | Assunto: $subject"

    local attachments_dir=$(extract_attachments "$email_file")

    if [ -z "$attachments_dir" ]; then
        log_message "WARNING" "Email sem anexos - ignorando"
        rm -f "$email_file"
        return 0
    fi

    local max_score=0
    local classification="CLEAN"

    find "$attachments_dir" -type f | while read -r attachment; do
        local file_name=$(basename "$attachment")
        local file_hash=$(sha256sum "$attachment" | awk '{print $1}')

        if [ -f "$FORENSIC_LOG" ] && grep -q "$file_hash" "$FORENSIC_LOG" 2>/dev/null; then
            log_message "INFO" "Arquivo já analisado: $file_name"
            continue
        fi

        local score=$(analyze_file "$attachment")

        [ $score -gt $max_score ] && max_score=$score

        if [ $score -ge 40 ]; then
            classification="INFECTED"

            local quarantine_file="${QUARANTINE_DIR}/${file_hash}_${file_name}"
            mv "$attachment" "$quarantine_file"
            log_message "ALERT" "ARQUIVO MALICIOSO: $file_name (Score: $score) -> Quarentena"
        else
            local clean_file="${ATTACHMENTS_DIR}/clean/${file_hash}_${file_name}"
            mv "$attachment" "$clean_file"
            log_message "INFO" "Arquivo limpo: $file_name (Score: $score)"
        fi

        local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
        [ ! -f "$FORENSIC_LOG" ] && \
            echo "timestamp,filename,sha256,score,classification,message_id,subject,from" > "$FORENSIC_LOG"

        echo "${timestamp},${file_name},${file_hash},${score},${classification},${message_id},${subject},${from}" \
            >> "$FORENSIC_LOG"
    done

    rmdir "$attachments_dir" 2>/dev/null

    move_email "$message_id" "$classification" "$subject"

    rm -f "$email_file"

    log_message "SUCCESS" "Email processado: $subject (Score máximo: $max_score)"
}

main() {
    log_message "INFO" "=== CALMA INICIADO ==="
    log_message "INFO" "Monitorando emails para análise..."

    mkdir -p "${INCOMING_DIR}" "${ATTACHMENTS_DIR}" "${ATTACHMENTS_DIR}/clean"
    mkdir -p "${REPORTS_DIR}" "${QUARANTINE_DIR}"
    mkdir -p "${LOG_DIR}/forensic" "${LOG_DIR}/analysis" "${LOG_DIR}/system"

    fetch_new_emails
    local new_count=$?

    if [ $new_count -eq 0 ]; then
        log_message "INFO" "Nenhum novo email encontrado"
    else
        log_message "INFO" "Processando $new_count novos emails"

        for email_file in "$INCOMING_DIR"/*.email; do
            [ -f "$email_file" ] || continue
            process_email "$email_file"
        done
    fi

    find "$INCOMING_DIR" -type f -mtime +1 -delete 2>/dev/null
    find "/tmp" -name "calma_*" -mtime +1 -delete 2>/dev/null

    log_message "INFO" "=== CALMA FINALIZADO ==="
}

main "$@"
