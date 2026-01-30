#!/usr/bin/env bash

set -e

detect_os() {
    case "$(uname -s)" in
        Linux*)     OS_TYPE="Linux" ;;
        Darwin*)    OS_TYPE="macOS" ;;
        CYGWIN*|MINGW*|MSYS*) OS_TYPE="Windows" ;;
        *)          OS_TYPE="Unknown" ;;
    esac
}

detect_os

BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_FILE="${BASE_DIR}/config/calma_config.json"

carregar_config_json() {
    if [ ! -f "$CONFIG_FILE" ]; then
        echo "ERRO: Arquivo de configuração $CONFIG_FILE não encontrado!"
        exit 1
    fi

    if ! command -v jq &> /dev/null; then
        echo "ERRO: 'jq' não está instalado!"
        echo ""
        echo "Instruções de instalação:"
        case "$OS_TYPE" in
            Linux)
                if [ -f /etc/debian_version ]; then
                    echo "  Ubuntu/Debian: sudo apt update && sudo apt install jq"
                elif [ -f /etc/fedora-release ]; then
                    echo "  Fedora/RHEL: sudo dnf install jq"
                elif [ -f /etc/arch-release ]; then
                    echo "  Arch Linux: sudo pacman -S jq"
                else
                    echo "  Use o gerenciador de pacotes da sua distribuição"
                fi
                ;;
            macOS)
                echo "  macOS: brew install jq"
                ;;
            Windows)
                echo "  Windows (Git Bash): Baixe de https://stedolan.github.io/jq/download/"
                echo "  Windows (WSL): sudo apt install jq"
                ;;
        esac
        echo ""
        exit 1
    fi

    EMAIL_USER=$(jq -r '.email_user // "calma.sandbox@gmail.com"' "$CONFIG_FILE")
    EMAIL_PASS=$(jq -r '.email_pass // ""' "$CONFIG_FILE")
    EMAIL_SERVER=$(jq -r '.email_server // "imap.gmail.com"' "$CONFIG_FILE")
    EMAIL_PORT=$(jq -r '.email_port // 993' "$CONFIG_FILE")
    
    MAX_FILE_SIZE=$(jq -r '.max_file_size // 10485760' "$CONFIG_FILE")
    SCAN_TIMEOUT=$(jq -r '.scan_timeout // 300' "$CONFIG_FILE")
    KEEP_LOGS_DAYS=$(jq -r '.keep_logs_days // 7' "$CONFIG_FILE")
    
    HASH_ALGORITHM=$(jq -r '.hash_algorithm // "sha256"' "$CONFIG_FILE")
    ENABLE_METADATA=$(jq -r '.enable_metadata // true' "$CONFIG_FILE")
}

carregar_config_json


LOGS_DIR="${BASE_DIR}/logs"
DATA_DIR="${BASE_DIR}/dados"
EMAIL_ATTACHMENTS_DIR="${DATA_DIR}/anexos_processados"
PENDING_DIR="${EMAIL_ATTACHMENTS_DIR}/a_analisar"
CLEAN_DIR="${EMAIL_ATTACHMENTS_DIR}/limpos"
INFECTED_DIR="${EMAIL_ATTACHMENTS_DIR}/infetados"
SUSPICIOUS_DIR="${EMAIL_ATTACHMENTS_DIR}/suspeitos"
QUARANTINE_DIR="${DATA_DIR}/quarentena"

REQUIRE_VM="true"
VM_WARNING_ONLY="false"

NEUTRALIZE_INFECTED="true"
NEUTRALIZE_SUSPICIOUS="true"
AUTO_DELETE_INFECTED_DAYS="30"
REMOVE_EXECUTE_PERMISSIONS="true"

SESSION_LOG="${LOGS_DIR}/execucao_$(date +%Y%m%d_%H%M%S).log"

inicializar_diretorios() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] Inicializando diretórios..."

    local dirs=("$LOGS_DIR" "$DATA_DIR" "$EMAIL_ATTACHMENTS_DIR"
                "$PENDING_DIR" "$CLEAN_DIR" "$INFECTED_DIR" "$SUSPICIOUS_DIR" "$QUARANTINE_DIR")

    for dir in "${dirs[@]}"; do
        if [ ! -d "$dir" ]; then
            mkdir -p "$dir"
            echo "  Criado: $dir"
        fi
    done

    touch "$SESSION_LOG"

    echo "Estrutura de diretórios verificada." >> "$SESSION_LOG" 2>/dev/null
}

log_message() {
    local level="$1"
    local message="$2"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')

    echo "[$timestamp] [$level] $message" >> "$SESSION_LOG" 2>/dev/null
}

calcular_hash() {
    local file_path="$1"

    if [ ! -f "$file_path" ]; then
        log_message "ERROR" "Ficheiro não encontrado para cálculo de hash: $file_path"
        echo "ERROR"
        return 1
    fi

    case $HASH_ALGORITHM in
        "md5")    hash_result=$(md5sum "$file_path" | cut -d' ' -f1) ;;
        "sha1")   hash_result=$(sha1sum "$file_path" | cut -d' ' -f1) ;;
        "sha256") hash_result=$(sha256sum "$file_path" | cut -d' ' -f1) ;;
        *)        hash_result=$(sha256sum "$file_path" | cut -d' ' -f1) ;;
    esac

    echo "$hash_result"
}

neutralizar_ficheiro() {
    local file_path="$1"
    local classification="$2"
    local basename_file=$(basename "$file_path")
    
    if [ "$REMOVE_EXECUTE_PERMISSIONS" = "true" ]; then
        chmod 000 "$file_path" 2>/dev/null
        log_message "SECURITY" "Permissões removidas: $basename_file"
    fi
    
    if [ "$classification" = "INFECTADO" ] && [ "$NEUTRALIZE_INFECTED" = "true" ]; then
        local extension="${basename_file##*.}"
        if [[ "$extension" =~ ^(exe|bat|cmd|ps1|dll|scr|vbs|js|jar|com|pif|msi)$ ]]; then
            local new_name="${file_path}.NEUTRALIZED.txt"
            mv "$file_path" "$new_name" 2>/dev/null
            log_message "SECURITY" "Ficheiro neutralizado: $basename_file -> $(basename "$new_name")"
            echo "$new_name"
            return 0
        fi
    fi
    
    if [ "$classification" = "SUSPEITO" ] && [ "$NEUTRALIZE_SUSPICIOUS" = "true" ]; then
        local extension="${basename_file##*.}"
        if [[ "$extension" =~ ^(exe|bat|cmd|ps1|dll|scr|vbs)$ ]]; then
            local new_name="${file_path}.QUARANTINE.txt"
            mv "$file_path" "$new_name" 2>/dev/null
            log_message "SECURITY" "Ficheiro em quarentena: $basename_file -> $(basename "$new_name")"
            echo "$new_name"
            return 0
        fi
    fi
    
    echo "$file_path"
}

gerar_metadados() {
    if [ "$ENABLE_METADATA" != "true" ]; then
        return
    fi

    local file_path="$1"
    local file_hash="$2"
    local email_origin="$3"
    local metadata_file="${file_path}.meta"

    {
        echo "=== METADADOS DO ANEXO ==="
        echo "Nome do ficheiro: $(basename "$file_path")"
        echo "Hash ($HASH_ALGORITHM): $file_hash"
        echo "Tamanho: $(stat -c%s "$file_path") bytes"
        echo "Email de origem: $email_origin"
        echo "Data de extração: $(date '+%Y-%m-%d %H:%M:%S')"
        echo "Localização original: $file_path"
        echo "----------------------------------------"
    } > "$metadata_file"

    log_message "INFO" "Metadados gerados: $metadata_file"
}


mover_email_para_label() {
    local email_id="$1"
    local label_name="$2"
    local classification="$3"
    local original_filename="$4"

    log_message "INFO" "Movendo email para label '$label_name' (Ficheiro: $original_filename)"

    python3 << PYTHON_EOF
import imaplib
import sys
import time
import re

def move_email_to_label(email_id, label_name, filename):
    mail = None
    try:
        clean_filename = filename.strip()
        if ':' in clean_filename:
            clean_filename = clean_filename.split(':')[-1].strip()
        
        print(f"[INFO] Procurando email com anexo '{clean_filename}'")
        
        mail = imaplib.IMAP4_SSL("imap.gmail.com", 993)
        mail.login("$EMAIL_USER", "$EMAIL_PASS")
        
        status, data = mail.select("INBOX", readonly=False)
        if status != "OK":
            print(f"[ERRO] Falha ao selecionar INBOX: {status}")
            return False
        
        print(f"[DEBUG] INBOX selecionada com sucesso")
        
        status, message_ids = mail.search(None, 'ALL')
        if status != "OK" or not message_ids[0]:
            print(f"[WARN] Nenhum email encontrado na INBOX")
            return False
        
        email_ids_list = message_ids[0].split()
        print(f"[DEBUG] Total de {len(email_ids_list)} emails na INBOX")
        
        found_id = None
        for eid in email_ids_list:
            try:
                status, msg_data = mail.fetch(eid, '(BODY.PEEK[])')
                if status != "OK":
                    continue
                
                raw_email = msg_data[0][1]
                email_text = raw_email.decode('utf-8', errors='ignore')
                
                if clean_filename.lower() in email_text.lower():
                    found_id = eid
                    print(f"[SUCCESS] Email encontrado: UID {eid.decode()}")
                    break
                    
            except Exception as e:
                print(f"[DEBUG] Erro ao processar email {eid}: {e}")
                continue
        
        if not found_id and email_id and str(email_id).isdigit():
            print(f"[WARN] Email não encontrado por nome, tentando UID {email_id}")
            found_id = str(email_id).encode()
        
        if not found_id:
            print(f"[ERRO] Email com anexo '{clean_filename}' não encontrado")
            return False
        
        print(f"[DEBUG] Copiando email para label '{label_name}'")
        status, result = mail.copy(found_id, label_name)
        
        if status != "OK":
            print(f"[ERRO] Falha ao copiar: {status} - {result}")
            return False
        
        print(f"[DEBUG] Email copiado - Status: {status}, Resultado: {result}")

        result_str = str(result)
        if 'COPYUID' not in result_str and 'Success' in result_str:
            print(f"[WARN] Cópia pode ter falhado (sem COPYUID). Verificando label...")
            
            time.sleep(1)
            status_check, data_check = mail.select(label_name, readonly=True)
            if status_check == "OK":
                status_search, messages_check = mail.search(None, 'ALL')
                count_before = len(messages_check[0].split()) if messages_check[0] else 0
                
                mail.select("INBOX", readonly=False)
                
                if count_before == 0:
                    print(f"[ERRO] Cópia falhou - Label '{label_name}' continua vazia")
                    print(f"[INFO] Gmail pode estar bloqueando este tipo de anexo (.exe, .scr, etc)")
                    return False
        
        print(f"[DEBUG] Removendo email da INBOX")
        status, result = mail.store(found_id, '+FLAGS', '\\\\Deleted')
        
        if status != "OK":
            print(f"[WARN] Falha ao marcar como deletado: {status}")
        
        mail.expunge()
        print(f"[DEBUG] INBOX expurgada")
        
        time.sleep(1)
        
        status, data = mail.select(label_name, readonly=True)
        if status == "OK":
            status, messages = mail.search(None, 'ALL')
            if status == "OK":
                count = len(messages[0].split()) if messages[0] else 0
                print(f"[INFO] Label '{label_name}' agora tem {count} emails")
        
        print(f"[SUCCESS] Email movido para '{label_name}' com sucesso!")
        return True
        
    except imaplib.IMAP4.error as e:
        print(f"[ERRO] Erro IMAP: {e}")
        return False
    except Exception as e:
        print(f"[ERRO] Erro inesperado: {e}")
        import traceback
        traceback.print_exc()
        return False
    finally:
        if mail:
            try:
                mail.close()
                mail.logout()
            except:
                pass

email_id = "$email_id"
label_name = "$label_name"
filename = "$original_filename"

success = move_email_to_label(email_id, label_name, filename)
sys.exit(0 if success else 1)
PYTHON_EOF

    local result=$?
    
    if [ $result -eq 0 ]; then
        log_message "SUCCESS" "Email movido para label '$label_name'"
        return 0
    else
        log_message "WARN" "Falha ao mover email para label '$label_name'"
        return 1
    fi
}


extrair_anexos_email() {
    log_message "INFO" "Iniciando extração de anexos da caixa de email..."

    local timestamp=$(date +%Y%m%d_%H%M%S)
    local email_map_file="${LOGS_DIR}/email_map_${timestamp}.txt"

    > "$email_map_file"

    local python_output=$(python3 << PYTHON_EOF
import imaplib
import email
import os
import re
from email.header import decode_header
from datetime import datetime

def extract_attachments():
    try:
        mail = imaplib.IMAP4_SSL("imap.gmail.com", 993)
        mail.login("$EMAIL_USER", "$EMAIL_PASS")
        mail.select("INBOX")

        status, messages = mail.search(None, 'UNSEEN')

        if status != "OK" or not messages[0]:
            print("INFO:Nenhum email novo encontrado.")
            mail.logout()
            return 0

        email_ids = messages[0].split()
        extracted = 0

        print(f"INFO:Encontrados {len(email_ids)} email(s) não lido(s).")

        with open("$email_map_file", "a", encoding='utf-8') as map_file:
            for email_id_bytes in email_ids:
                email_id = email_id_bytes.decode('utf-8')

                status, msg_data = mail.fetch(email_id_bytes, '(RFC822)')

                if status != "OK":
                    print(f"AVISO:Falha ao buscar email {email_id}")
                    continue

                msg = email.message_from_bytes(msg_data[0][1])
                from_header = msg["From"] or "Desconhecido"

                subject = "Sem assunto"
                if msg["Subject"]:
                    try:
                        decoded_parts = decode_header(msg["Subject"])
                        for content, encoding in decoded_parts:
                            if isinstance(content, bytes):
                                if encoding:
                                    subject = content.decode(encoding)
                                else:
                                    subject = content.decode('utf-8', 'ignore')
                            else:
                                subject = str(content)
                            break
                    except Exception:
                        subject = "Erro na decodificação"

                print(f"PROCESSANDO:Email ID: {email_id} | De: {from_header} | Assunto: {subject[:50]}")

                part_num = 0
                for part in msg.walk():
                    content_disposition = part.get_content_disposition()

                    if content_disposition == 'attachment':
                        filename = part.get_filename()

                        if filename:
                            part_num += 1

                            if isinstance(filename, bytes):
                                decoded_part, encoding = decode_header(filename)[0]
                                if isinstance(decoded_part, bytes):
                                    if encoding:
                                        filename = decoded_part.decode(encoding)
                                    else:
                                        filename = decoded_part.decode('utf-8', 'ignore')
                                else:
                                    filename = str(decoded_part)

                            timestamp_str = datetime.now().strftime("%Y%m%d_%H%M%S")
                            safe_name = re.sub(r'[^\w\.\-]', '_', filename)
                            final_name = f"{timestamp_str}_{part_num}_{safe_name}"

                            filepath = os.path.join("$PENDING_DIR", final_name)

                            file_content = part.get_payload(decode=True)
                            if len(file_content) > int("$MAX_FILE_SIZE"):
                                print(f"AVISO:Ficheiro muito grande ignorado: {filename} ({len(file_content)} bytes)")
                                continue

                            with open(filepath, 'wb') as f:
                                f.write(file_content)

                            map_line = f"{email_id}:{final_name}:{from_header}:{subject}:{filename}"
                            map_file.write(map_line + "\\n")

                            print(f"EXTRAIDO:{email_id}:{final_name}:{filename}:{from_header}:{len(file_content)}")
                            extracted += 1

                if part_num > 0:
                    mail.store(email_id_bytes, '+FLAGS', '\\\\Seen')
                    print(f"INFO:Email {email_id} marcado como lido")

        mail.logout()
        print(f"RESULTADO:{extracted}")
        return extracted

    except Exception as e:
        print(f"ERRO:Erro na extração: {str(e)}")
        import traceback
        traceback.print_exc()
        return -1

count = extract_attachments()
PYTHON_EOF
)

    local extracted_count=0

    while IFS= read -r line; do
        case "$line" in
            INFO:*)
                log_message "INFO" "${line#INFO:}"
                if [[ "${line#INFO:}" =~ ([0-9]+).*email.*não.lido ]]; then
                    extracted_count=1
                fi
                ;;
            PROCESSANDO:*)
                log_message "INFO" "${line#PROCESSANDO:}"
                ;;
            AVISO:*)
                log_message "WARN" "${line#AVISO:}"
                ;;
            ERRO:*)
                log_message "ERROR" "${line#ERRO:}"
                ;;
            EXTRAIDO:*)
                IFS=':' read -r email_id final_name original_name from_addr file_size <<< "${line#EXTRAIDO:}"
                if [ -f "$PENDING_DIR/$final_name" ]; then
                    file_hash=$(calcular_hash "$PENDING_DIR/$final_name")
                    gerar_metadados "$PENDING_DIR/$final_name" "$file_hash" "$from_addr"
                    log_message "SUCCESS" "Anexo extraído: $original_name ($file_size bytes) | Email ID: $email_id"
                    extracted_count=$((extracted_count + 1))
                fi
                ;;
            RESULTADO:*)
                local result="${line#RESULTADO:}"
                if [ "$result" -ge 0 ]; then
                    log_message "INFO" "Extração concluída. Total de anexos extraídos: $result"
                    extracted_count="$result"
                fi
                ;;
        esac
    done <<< "$python_output"

    return $extracted_count
}


calcular_score_risco() {
    local file_path="$1"
    local filename
    filename=$(basename "$file_path")

    local base_dir="${CALMA_DIR:-}"
    if [ -z "$base_dir" ]; then
        base_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    fi

    local detector="$base_dir/scripts/detection/detect_malware_universal.py"

    if [ -f "$detector" ]; then
        local score_out
        score_out=$(python3 "$detector" "$file_path" --score-only 2>/dev/null || true)
        if [[ "$score_out" =~ ^[0-9]+$ ]]; then
            if [ "$score_out" -lt 0 ]; then score_out=0; fi
            if [ "$score_out" -gt 100 ]; then score_out=100; fi
            echo "$score_out"
            return 0
        fi
    fi

    local extension="${filename##*.}"
    local score=30

    case "${extension,,}" in
        exe|dll|scr)
            score=90
            ;;
        bat|cmd|ps1|vbs)
            score=85
            ;;
        js|jar|wsf|hta)
            score=75
            ;;
        zip|rar|7z|tar|gz)
            score=55
            ;;
        pdf)
            score=40
            ;;
        doc|docx|xls|xlsx|ppt|pptx)
            score=45
            ;;
        txt|md|rtf)
            score=10
            ;;
        png|jpg|jpeg|gif|bmp)
            score=5
            ;;
        *)
            score=30
            ;;
    esac

    if [[ "${filename,,}" =~ (virus|malware|trojan|worm|ransom|keylogger|spyware|exploit|backdoor) ]]; then
        score=95
    elif [[ "${filename,,}" =~ (suspeito|suspicious|danger) ]]; then
        score=60
    elif [[ "${filename,,}" =~ (safe|seguro|clean|teste|sample|demo|exemplo) ]]; then
        score=5
    fi

    if [ $score -lt 0 ]; then score=0; fi
    if [ $score -gt 100 ]; then score=100; fi

    echo "$score"
}


processar_anexos_pendentes() {
    log_message "INFO" "Processando anexos pendentes..."

    local pending_count=$(find "$PENDING_DIR" -type f ! -name "*.meta" 2>/dev/null | wc -l)

    if [ $pending_count -eq 0 ]; then
        log_message "INFO" "Nenhum anexo pendente para processar."
        return 0
    fi

    log_message "INFO" "Encontrados $pending_count anexo(s) pendente(s)."

    local map_files=("$LOGS_DIR"/email_map_*.txt)
    local latest_map=""

    if [ ${#map_files[@]} -gt 0 ] && [ -e "${map_files[0]}" ]; then
        latest_map=$(ls -t "${map_files[@]}" 2>/dev/null | head -1)
    fi
    
    if [ ! -f "$latest_map" ] || [ ! -s "$latest_map" ]; then
        if [ -f "$LOGS_DIR/email_map_correcao.txt" ]; then
            latest_map="$LOGS_DIR/email_map_correcao.txt"
            log_message "INFO" "Usando ficheiro de mapeamento de correção"
        fi
    fi

    declare -A email_map
    if [ -f "$latest_map" ]; then
        log_message "INFO" "Carregando mapeamento de: $(basename "$latest_map")"
        while IFS=':' read -r email_id final_name from_addr subject original_filename; do
            final_name=$(echo "$final_name" | xargs)
            email_id=$(echo "$email_id" | xargs)
            email_map["$final_name"]="$email_id:$from_addr:$subject:$original_filename"
        done < "$latest_map"

        log_message "INFO" "Mapeamento carregado: ${#email_map[@]} entradas"
    else
        log_message "WARN" "Ficheiro de mapeamento não encontrado"
    fi

    local processed_files=0

    local files_to_process=()
    while IFS= read -r -d $'\0' file; do
        if [[ "$file" != *.meta ]]; then
            files_to_process+=("$file")
        fi
    done < <(find "$PENDING_DIR" -maxdepth 1 -type f ! -name "*.meta" -print0 2>/dev/null)

    for file_path in "${files_to_process[@]}"; do
        local filename=$(basename "$file_path")
        local file_hash=$(calcular_hash "$file_path")

        log_message "INFO" "A processar: $filename (Hash: ${file_hash:0:16}...)"

        local email_info="${email_map[$filename]}"
        local email_id=""
        local original_filename="$filename"
        local email_from="Desconhecido"
        local email_subject="Sem assunto"

        if [ -n "$email_info" ]; then
            IFS=':' read -r email_id email_from email_subject original_filename <<< "$email_info"
            original_filename=$(echo "$original_filename" | xargs)
            log_message "INFO" "Email original ID: $email_id | De: $email_from"
        else
            log_message "WARN" "Email ID não encontrado no mapeamento para: $filename"
            if [[ "$filename" =~ ^[0-9]+_[0-9]+_(.+)$ ]]; then
                original_filename="${BASH_REMATCH[1]}"
            fi
        fi

        local score=$(calcular_score_risco "$file_path")

        log_message "INFO" "Análise concluída. Score: $score/100"

        local classification
        local destination
        local label_name

        if [ "$score" -ge 75 ]; then
            classification="INFECTADO"
            destination="$INFECTED_DIR"
            label_name="Infected"
        elif [ "$score" -ge 50 ]; then
            classification="SUSPEITO"
            destination="$SUSPICIOUS_DIR"
            label_name="Suspicious"
        else
            classification="LIMPO"
            destination="$CLEAN_DIR"
            label_name="Clean"
        fi

        if [ -n "$email_id" ] && [[ "$email_id" =~ ^[0-9]+$ ]]; then
            log_message "INFO" "A mover email $email_id para label '$label_name'..."

            mover_email_para_label "$email_id" "$label_name" "$classification" "$original_filename"
            local move_result=$?

            if [ $move_result -eq 0 ]; then
                log_message "SUCCESS" "Email $email_id movido para label '$label_name'"
            else
                log_message "WARN" "Falha ao mover email $email_id para '$label_name' (código: $move_result)"
                
                if [ "$label_name" = "Infected" ]; then
                    log_message "INFO" "Gmail pode estar bloqueando anexo perigoso (.exe). Tentando mover para 'Suspicious'..."
                    
                    mover_email_para_label "$email_id" "Suspicious" "$classification" "$original_filename"
                    local fallback_result=$?
                    
                    if [ $fallback_result -eq 0 ]; then
                        log_message "SUCCESS" "Email movido para 'Suspicious' (fallback)"
                        label_name="Suspicious (Infected bloqueado)"
                    else
                        log_message "ERROR" "Falha no fallback. Email permanece na INBOX"
                    fi
                fi
            fi
        else
            log_message "INFO" "Email não movido (ID inválido ou não disponível): $email_id"
        fi

        local neutralized_path=$(neutralizar_ficheiro "$file_path" "$classification")
        local final_filename=$(basename "$neutralized_path")
        local destination_file="$destination/$final_filename"
        
        if mv "$neutralized_path" "$destination_file"; then
            log_message "INFO" "Ficheiro movido para: $destination"
        else
            log_message "ERROR" "Falha ao mover ficheiro para $destination"
        fi

        if [ -f "${file_path}.meta" ]; then
            mv "${file_path}.meta" "$destination/"
        fi

        local meta_file="$destination/${final_filename}.meta"
        if [ -f "${file_path}.meta" ]; then
            mv "${file_path}.meta" "$meta_file" 2>/dev/null
        fi
        
        {
            echo ""
            echo "=== RESULTADO DA ANÁLISE ==="
            echo "Task ID: $task_id"
            echo "Score: $score/100"
            echo "Classificação: $classification"
            echo "Data da análise: $(date '+%Y-%m-%d %H:%M:%S')"
            echo "Destino final: $destination"
            echo "Email ID original: $email_id"
            echo "Label Gmail: $label_name"
            echo "Remetente: $email_from"
            echo "Assunto: $email_subject"
            echo ""
            echo "=== MEDIDAS DE SEGURANÇA ==="
            echo "Nome original: $filename"
            echo "Nome final: $final_filename"
            echo "Permissões removidas: $([ "$REMOVE_EXECUTE_PERMISSIONS" = "true" ] && echo "SIM" || echo "NÃO")"
            echo "Ficheiro neutralizado: $([ "$filename" != "$final_filename" ] && echo "SIM" || echo "NÃO")"
        } >> "$meta_file"

        log_message "SUCCESS" "Classificado: $filename -> $classification (Score: $score/100)"
        processed_files=$((processed_files + 1))

        sleep 1
    done

    log_message "INFO" "Processamento concluído. $processed_files/$pending_count ficheiro(s) processado(s)."

    if [ $processed_files -gt 0 ]; then
        find "$PENDING_DIR" -type f -delete 2>/dev/null
        log_message "INFO" "Pasta pendente limpa."
    fi

    if [ -f "$latest_map" ]; then
        rm "$latest_map"
        log_message "INFO" "Ficheiro de mapeamento removido: $(basename "$latest_map")"
    fi

    return $processed_files
}


gerar_relatorio_execucao() {
    local total_clean=$(find "$CLEAN_DIR" -type f ! -name "*.meta" 2>/dev/null | wc -l)
    local total_infected=$(find "$INFECTED_DIR" -type f ! -name "*.meta" 2>/dev/null | wc -l)
    local total_suspicious=$(find "$SUSPICIOUS_DIR" -type f ! -name "*.meta" 2>/dev/null | wc -l)
    local total_pending=$(find "$PENDING_DIR" -type f ! -name "*.meta" 2>/dev/null | wc -l)

    local report_file="${LOGS_DIR}/relatorio_$(date +%Y%m%d_%H%M%S).txt"

    {
        echo "=================================================="
        echo "       RELATÓRIO DO SISTEMA DE ANÁLISE"
        echo "         $(date '+%d/%m/%Y %H:%M:%S')"
        echo "=================================================="
        echo ""
        echo "ESTATÍSTICAS DE CLASSIFICAÇÃO:"
        echo "  • Ficheiros LIMPOS:       $total_clean"
        echo "  • Ficheiros INFETADOS:    $total_infected"
        echo "  • Ficheiros SUSPEITOS:    $total_suspicious"
        echo "  • Ficheiros PENDENTES:    $total_pending"
        echo ""
        echo "CONFIGURAÇÃO:"
        echo "  • Email: $EMAIL_USER"
        echo "  • Diretório base: $BASE_DIR"
        echo ""
        echo "ÚLTIMAS AÇÕES:"
        echo "  • Emails movidos para labels no Gmail"
        echo "  • Ficheiros classificados e organizados"
        echo "  • Labels utilizadas: Infected, Suspicious, Clean"
        echo ""
        if [ $total_infected -gt 0 ]; then
            echo "ALERTA: Ficheiros infetados detetados!"
            find "$INFECTED_DIR" -type f ! -name "*.meta" -printf "    %f (Detetado em %TY-%Tm-%Td %TH:%TM)\\n" | tail -5
        fi
        echo ""
        echo "LOG DA SESSÃO: $SESSION_LOG"
        echo "=================================================="
    } > "$report_file"

    log_message "INFO" "Relatório gerado: $report_file"

    echo ""
    echo "=================================================="
    echo "            RELATÓRIO DE EXECUÇÃO"
    echo "=================================================="
    echo "   Ficheiros LIMPOS:     $total_clean"
    echo "   Ficheiros INFETADOS:  $total_infected"
    echo "   Ficheiros SUSPEITOS:  $total_suspicious"
    echo "   Ficheiros PENDENTES:   $total_pending"
    echo ""
    echo "   Emails movidos para labels no Gmail"
    echo "   Relatório detalhado: $report_file"
    echo ""
}

limpar_logs_antigos() {
    log_message "INFO" "Limpando logs antigos (>$KEEP_LOGS_DAYS dias)..."
    find "$LOGS_DIR" -type f -name "*.log" -mtime +$KEEP_LOGS_DAYS -delete 2>/dev/null
    find "$LOGS_DIR" -type f -name "relatorio_*.txt" -mtime +$KEEP_LOGS_DAYS -delete 2>/dev/null
    find "$LOGS_DIR" -type f -name "email_map_*.txt" -mtime +1 -delete 2>/dev/null
    log_message "INFO" "Limpeza de logs concluída."
}

limpar_ficheiros_infectados_antigos() {
    if [ -n "$AUTO_DELETE_INFECTED_DAYS" ] && [ "$AUTO_DELETE_INFECTED_DAYS" -gt 0 ]; then
        log_message "SECURITY" "Removendo ficheiros infectados com mais de $AUTO_DELETE_INFECTED_DAYS dias..."
        local count=$(find "$INFECTED_DIR" -type f -mtime +$AUTO_DELETE_INFECTED_DAYS 2>/dev/null | wc -l)
        find "$INFECTED_DIR" -type f -mtime +$AUTO_DELETE_INFECTED_DAYS -delete 2>/dev/null
        log_message "SECURITY" "$count ficheiro(s) infectado(s) antigo(s) removido(s)"
    fi
}

verificar_dependencias() {
    log_message "INFO" "Verificando dependências..."
    local missing_deps=0

    for cmd in python3; do
        if ! command -v $cmd &> /dev/null; then
            log_message "ERROR" "Comando '$cmd' não encontrado."
            missing_deps=$((missing_deps + 1))
        else
            log_message "INFO" " $cmd encontrado"
        fi
    done

    if [ $missing_deps -gt 0 ]; then
        log_message "ERROR" "Faltam dependências Python!"
        echo ""
        echo "Python 3 não encontrado. Instruções:"
        case "$OS_TYPE" in
            Linux)
                echo "  Ubuntu/Debian: sudo apt update && sudo apt install python3"
                echo "  Fedora/RHEL: sudo dnf install python3"
                echo "  Arch Linux: sudo pacman -S python"
                ;;
            macOS)
                echo "  macOS: brew install python@3.10"
                ;;
            Windows)
                echo "  Windows: https://www.python.org/downloads/"
                echo "  ou: winget install Python.Python.3.10"
                ;;
        esac
        echo ""
        return 1
    fi

    log_message "SUCCESS" "Dependências verificadas."
    return 0
}

verificar_ambiente_virtual() {
    log_message "SECURITY" "Verificando ambiente de execução..."
    
    local is_vm=false
    local vm_type="Desconhecido"
    
    if [ -f /sys/class/dmi/id/product_name ]; then
        local product_name=$(cat /sys/class/dmi/id/product_name 2>/dev/null)
        case "$product_name" in
            *VirtualBox*)
                is_vm=true
                vm_type="VirtualBox"
                ;;
            *VMware*)
                is_vm=true
                vm_type="VMware"
                ;;
            *KVM*|*QEMU*)
                is_vm=true
                vm_type="KVM/QEMU"
                ;;
            *Xen*)
                is_vm=true
                vm_type="Xen"
                ;;
        esac
    fi
    
    if [ "$is_vm" = false ]; then
        if [ -f /sys/class/dmi/id/sys_vendor ]; then
            local sys_vendor=$(cat /sys/class/dmi/id/sys_vendor 2>/dev/null)
            case "$sys_vendor" in
                *QEMU*|*VirtualBox*|*VMware*|*innotek*|*Xen*|*Parallels*)
                    is_vm=true
                    vm_type="$sys_vendor"
                    ;;
            esac
        fi
    fi
    
    if [ "$is_vm" = false ]; then
        if lscpu 2>/dev/null | grep -q "Hypervisor vendor"; then
            is_vm=true
            vm_type=$(lscpu | grep "Hypervisor vendor" | cut -d: -f2 | xargs)
        fi
    fi
    
    if [ "$is_vm" = false ]; then
        if command -v systemd-detect-virt &> /dev/null; then
            if systemd-detect-virt --quiet 2>/dev/null; then
                is_vm=true
                vm_type=$(systemd-detect-virt 2>/dev/null)
            fi
        fi
    fi
    
    if [ "$is_vm" = true ]; then
        log_message "SUCCESS" "Ambiente Virtual detectado: $vm_type"
        echo ""
        echo "  ✓ Ambiente seguro detectado: $vm_type"
        echo "  ✓ Sistema pode processar ficheiros com segurança"
        echo ""
        return 0
    else
        echo ""
        echo "    AVISO DE SEGURANÇA "
        echo ""
        echo "  Este sistema NÃO está a correr numa Máquina Virtual!"
        echo ""
        echo "  RECOMENDAÇÃO FORTE:"
        echo "  - Execute este sistema APENAS em máquinas virtuais"
        echo "  - VirtualBox, VMware, QEMU, Hyper-V, etc."
        echo ""
        echo "  PORQUÊ?"
        echo "  - Proteção contra malware acidental"
        echo "  - Isolamento total do sistema host"
        echo "  - Possibilidade de snapshots/rollback"
        echo "  - Ambiente controlado para análise de ficheiros"
        echo ""
        
        if [ "$REQUIRE_VM" = "true" ] && [ "$VM_WARNING_ONLY" = "false" ]; then
            echo "  EXECUÇÃO BLOQUEADA"
            echo ""
            echo "  Configure REQUIRE_VM=\"false\" no script para ignorar"
            echo "  ou VM_WARNING_ONLY=\"true\" para apenas avisar"
            echo ""
            log_message "ERROR" "Execução bloqueada - VM não detectada"
            return 1
        else
            echo "  Continuando mesmo assim..."
            echo "  (Configurado para: $([ "$VM_WARNING_ONLY" = "true" ] && echo "AVISAR APENAS" || echo "PERMITIR"))"
            echo ""
            log_message "WARN" "Sistema a correr FORA de VM - RISCO ELEVADO"
            
            read -p "  Pressione ENTER para continuar ou CTRL+C para cancelar..." -t 10
            echo ""
            return 0
        fi
    fi
}


verificar_labels() {
    log_message "INFO" "Verificando se as labels existem no Gmail..."

    python3 << PYTHON_EOF
import imaplib

def check_labels():
    try:
        mail = imaplib.IMAP4_SSL("imap.gmail.com", 993)
        mail.login("$EMAIL_USER", "$EMAIL_PASS")

        print("=== VERIFICAÇÃO DE LABELS ===")

        status, folders = mail.list()

        if status == "OK":
            labels_exist = {"Infected": False, "Suspicious": False, "Clean": False}

            for folder in folders:
                folder_str = folder.decode()
                print(f"Pasta encontrada: {folder_str}")

                if '"Infected"' in folder_str or 'Infected' in folder_str:
                    labels_exist["Infected"] = True
                if '"Suspicious"' in folder_str or 'Suspicious' in folder_str:
                    labels_exist["Suspicious"] = True
                if '"Clean"' in folder_str or 'Clean' in folder_str:
                    labels_exist["Clean"] = True

            print("\\n=== STATUS DAS LABELS ===")
            for label, exists in labels_exist.items():
                status = " EXISTE" if exists else " NÃO EXISTE"
                print(f"{label}: {status}")

            missing = [label for label, exists in labels_exist.items() if not exists]
            if missing:
                print(f"\\nAVISO: Labels em falta: {', '.join(missing)}")
                print("Execute: ./labels.sh para criar as labels")

        mail.logout()

    except Exception as e:
        print(f"ERRO: {e}")

check_labels()
PYTHON_EOF
}


main() {
    echo ""
    echo "  ██████╗ █████╗ ██╗     ███╗   ███╗ █████╗ "
    echo " ██╔════╝██╔══██╗██║     ████╗ ████║██╔══██╗"
    echo " ██║     ███████║██║     ██╔████╔██║███████║"
    echo " ██║     ██╔══██║██║     ██║╚██╔╝██║██╔══██║"
    echo "  ██████╗██║  ██║███████╗██║ ╚═╝ ██║██║  ██║"
    echo "  ╚═════╝╚═╝  ╚═╝╚══════╝╚═╝     ╚═╝╚═╝  ╚═╝"
    echo "    Sistema Automático de Análise de Anexos"
    echo "         $(date '+%d/%m/%Y %H:%M:%S')" 
    echo ""

    verificar_labels
    echo ""

    if ! verificar_ambiente_virtual; then
        exit 1
    fi

    inicializar_diretorios
    log_message "INFO" "Iniciando sistema..."

    if ! verificar_dependencias; then
        log_message "ERROR" "Sistema abortado."
        exit 1
    fi

    log_message "PHASE" "FASE 1: Extração de anexos"
    extrair_anexos_email
    local extracted=$?

    log_message "PHASE" "FASE 2: Análise e classificação"
    processar_anexos_pendentes
    local processed=$?

    log_message "PHASE" "FASE 3: Manutenção"
    limpar_logs_antigos
    limpar_ficheiros_infectados_antigos

    log_message "PHASE" "FASE 4: Relatório"
    gerar_relatorio_execucao

    log_message "SUCCESS" "Execução concluída!"
    echo ""
    echo " Sistema executado com sucesso!"
    echo " Anexos processados: $processed"
    echo ""

    echo " Para verificar:"
    echo "   1. Abra o Gmail no navegador"
    echo "   2. Veja na sidebar esquerda se as labels aparecem"
    echo "   3. Clique em cada label para ver os emails dentro"
    echo ""
}

main "$@"
exit 0
