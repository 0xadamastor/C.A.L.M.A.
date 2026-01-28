#!/bin/bash

EMAIL_USER="email@gmail.com"
EMAIL_PASS="xxxx xxxx xxxx xxxx"
EMAIL_SERVER="imap.gmail.com"
EMAIL_PORT="993"

SANDBOX_ENABLED="false"
SANDBOX_URL="http://localhost:8090"
SANDBOX_API_KEY=""

BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOGS_DIR="${BASE_DIR}/logs"
DATA_DIR="${BASE_DIR}/dados"
EMAIL_ATTACHMENTS_DIR="${DATA_DIR}/anexos_processados"
PENDING_DIR="${EMAIL_ATTACHMENTS_DIR}/a_analisar"
CLEAN_DIR="${EMAIL_ATTACHMENTS_DIR}/limpos"
INFECTED_DIR="${EMAIL_ATTACHMENTS_DIR}/infetados"
QUARANTINE_DIR="${DATA_DIR}/quarentena"

MAX_FILE_SIZE="10485760"
SCAN_TIMEOUT="300"
KEEP_LOGS_DAYS="7"

HASH_ALGORITHM="sha256"
ENABLE_METADATA="true"


inicializar_diretorios() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] Inicializando diretórios..."

    local dirs=("$LOGS_DIR" "$DATA_DIR" "$EMAIL_ATTACHMENTS_DIR"
                "$PENDING_DIR" "$CLEAN_DIR" "$INFECTED_DIR" "$QUARANTINE_DIR")

    for dir in "${dirs[@]}"; do
        if [ ! -d "$dir" ]; then
            mkdir -p "$dir"
            echo "  Criado: $dir"
        fi
    done

    SESSION_LOG="${LOGS_DIR}/execucao_$(date +%Y%m%d_%H%M%S).log"
    touch "$SESSION_LOG"

    echo "Estrutura de diretórios verificada." | tee -a "$SESSION_LOG" 2>/dev/null
}

log_message() {
    local level="$1"
    local message="$2"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')

    echo "[$timestamp] [$level] $message" | tee -a "$SESSION_LOG" 2>/dev/null
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
import email as email_lib
from email.header import decode_header

def move_email_to_label(email_id, label_name, search_term):
    try:
        filename = search_term.split(':')[-1].strip() if ':' in search_term else search_term
        print(f"DEBUG: Procurando email com '{filename}' para mover para '{label_name}'")

        mail = imaplib.IMAP4_SSL("imap.gmail.com", 993)
        mail.login("$EMAIL_USER", "$EMAIL_PASS")

        mail.select("INBOX")
        print(f"DEBUG: Inbox selecionada")

        found_email_id = None
        
        try:
            keyword = filename.split('.')[0] if '.' in filename else filename
            status, data = mail.search(None, 'ALL')
            
            if status == "OK" and data[0]:
                for eid in data[0].split():
                    try:
                        status, msg_data = mail.fetch(eid, '(RFC822)')
                        if status == "OK":
                            email_content = msg_data[0][1].decode('utf-8', errors='ignore')
                            if (filename.lower() in email_content.lower() or 
                                keyword.lower() in email_content.lower()):
                                found_email_id = eid
                                print(f"DEBUG: Email encontrado com ID {eid.decode()}")
                                break
                    except Exception as search_error:
                        continue
        except Exception as e:
            print(f"DEBUG: Erro na busca iterativa: {e}")
        
        if not found_email_id:
            print(f"ERRO: Email com '{filename}' não encontrado na inbox")
            if email_id and email_id.isdigit():
                print(f"DEBUG: Tentando com ID {email_id}")
                status, data = mail.fetch(str(email_id).encode(), '(RFC822)')
                if status == "OK":
                    found_email_id = str(email_id).encode()
                    print(f"DEBUG: Email encontrado com ID {email_id}")
                else:
                    mail.logout()
                    return False
            else:
                mail.logout()
                return False

        result = mail.copy(found_email_id, label_name)
        print(f"DEBUG: Resultado do COPY: {result}")

        if result[0] == "OK":
            mail.store(found_email_id, '+FLAGS', '\\\\Deleted')
            mail.expunge()
            print(f"DEBUG: Email marcado como deletado e inbox expurgada")

            mail.logout()

            time.sleep(2)

            mail2 = imaplib.IMAP4_SSL("imap.gmail.com", 993)
            mail2.login("$EMAIL_USER", "$EMAIL_PASS")

            mail2.select(label_name)
            status, messages = mail2.search(None, 'ALL')
            if status == "OK":
                count = len(messages[0].split())
                print(f"DEBUG: Label '{label_name}' agora tem {count} emails")

            mail2.logout()

            print("SUCCESS:Email movido com sucesso para a label")
            return True
        else:
            print(f"ERRO:Falha ao mover email: {result}")
            mail.logout()
            return False

    except Exception as e:
        error_msg = str(e)
        print(f"ERRO:Erro ao mover email: {error_msg}")
        import traceback
        traceback.print_exc()
        return False

email_id = "$email_id"
label_name = "$label_name"
search_term = "$original_filename"
success = move_email_to_label(email_id, label_name, search_term)
sys.exit(0 if success else 1)
PYTHON_EOF

    local result=$?
    return $result
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
                    extracted_count=1  # Temos emails para processar
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


submeter_sandbox_simulada() {
    local file_path="$1"
    local filename=$(basename "$file_path")

    local task_id=$((RANDOM % 9000 + 1000))

    local score=0
    local extension="${filename##*.}"

    case "$extension" in
        exe|bat|cmd|ps1|vbs|dll|scr)
            score=$((80 + RANDOM % 20))  # Alto risco (80-100)
            ;;
        js|jar|wsf|hta)
            score=$((60 + RANDOM % 30))  # Médio-alto risco (60-90)
            ;;
        zip|rar|7z)
            score=$((40 + RANDOM % 30))  # Risco médio (40-70)
            ;;
        pdf|doc|docx|xls|xlsx|ppt|pptx)
            score=$((20 + RANDOM % 40))  # Risco variável (20-60)
            ;;
        txt|png|jpg|jpeg|gif|mp3|mp4|avi|mpg)
            score=$((0 + RANDOM % 20))   # Baixo risco (0-20)
            ;;
        *)
            score=$((RANDOM % 100))
            ;;
    esac

    if [[ "$filename" =~ (virus|malware|trojan|worm|ransom|keylogger|spyware|hack|crack|exploit|malicioso|infeccao) ]]; then
        score=85  # Ficheiros claramente maliciosos -> INFECTADOS (≥70)
    elif [[ "$filename" =~ (suspeito|suspicious|danger) ]]; then
        score=50  # Ficheiros suspeitos -> SUSPICIOUS (30-69)
    elif [[ "$filename" =~ (seguro|safe|clean|teste|demo|exemplo|sample|documento|relatorio|report) ]]; then
        score=10  # Ficheiros claramente seguros -> CLEAN (<30)
    fi

    if [ $score -lt 0 ]; then score=0; fi
    if [ $score -gt 100 ]; then score=100; fi

    echo "$task_id:$score"
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

        local task_id_result=$(submeter_sandbox_simulada "$file_path")
        local task_id=$(echo "$task_id_result" | cut -d: -f1)
        local score=$(echo "$task_id_result" | cut -d: -f2)

        log_message "INFO" "Análise concluída. Score: $score/100"

        local classification
        local destination
        local label_name

        if [ "$score" -ge 70 ]; then
            classification="INFECTADO"
            destination="$INFECTED_DIR"
            label_name="Infected"
        elif [ "$score" -ge 30 ]; then
            classification="SUSPEITO"
            destination="$QUARANTINE_DIR"
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
                log_message "SUCCESS" " Email $email_id movido para label '$label_name'"
            else
                log_message "WARN" " Falha ao mover email $email_id (código: $move_result)"
            fi
        else
            log_message "INFO" "Email não movido (ID inválido ou não disponível): $email_id"
        fi

        local destination_file="$destination/$filename"
        if mv "$file_path" "$destination_file"; then
            log_message "INFO" "Ficheiro movido para: $destination"
        else
            log_message "ERROR" "Falha ao mover ficheiro para $destination"
        fi

        if [ -f "${file_path}.meta" ]; then
            mv "${file_path}.meta" "$destination/"
        fi

        local meta_file="$destination/${filename}.meta"
        if [ -f "$meta_file" ]; then
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
            } >> "$meta_file"
        fi

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
    local total_quarantine=$(find "$QUARANTINE_DIR" -type f ! -name "*.meta" 2>/dev/null | wc -l)
    local total_pending=$(find "$PENDING_DIR" -type f ! -name "*.meta" 2>/dev/null | wc -l)

    local report_file="${LOGS_DIR}/relatorio_$(date +%Y%m%d_%H%M%S).txt"

    {
        echo "=================================================="
        echo "       RELATÓRIO DO SISTEMA DE ANÁLISE"
        echo "                 $(date '+%d/%m/%Y %H:%M:%S')"
        echo "=================================================="
        echo ""
        echo "ESTATÍSTICAS DE CLASSIFICAÇÃO:"
        echo "  • Ficheiros LIMPOS:       $total_clean"
        echo "  • Ficheiros INFETADOS:    $total_infected"
        echo "  • Ficheiros em QUARENTENA: $total_quarantine"
        echo "  • Ficheiros PENDENTES:    $total_pending"
        echo ""
        echo "CONFIGURAÇÃO:"
        echo "  • Modo: $( [ "$SANDBOX_ENABLED" = "true" ] && echo "SANDBOX REAL" || echo "MODO SIMULAÇÃO" )"
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
    echo "   Ficheiros SUSPEITOS:  $total_quarantine"
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
        log_message "ERROR" "Faltam dependências. Instale com: sudo apt install python3"
        return 1
    fi

    log_message "SUCCESS" "Dependências verificadas."
    return 0
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
