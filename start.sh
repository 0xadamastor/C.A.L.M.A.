#!/bin/bash

# C.A.L.M.A. - Script de Inicialização

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Banner
echo -e "${BLUE}"
echo "┌─────────────────────────────────────────────────────────────┐"
echo "│                      C.A.L.M.A.                            │"
echo "│               Sistema de Análise de Anexos                 │"
echo "└─────────────────────────────────────────────────────────────┘"
echo -e "${NC}"

# Verificar configuração
if [ ! -f "${BASE_DIR}/.env" ]; then
    echo -e "${RED}❌ Sistema não configurado!${NC}"
    echo "Execute './setup.sh' primeiro."
    exit 1
fi

# Carregar configurações
source "${BASE_DIR}/config/config.sh"

show_menu() {
    echo -e "${GREEN}Escolha uma opção:${NC}"
    echo
    echo "1) 🔍 Executar análise de anexos"
    echo "2) 🌐 Iniciar interface web"
    echo "3) 📧 Configurar labels do Gmail"
    echo "4) ⏰ Configurar cron job"
    echo "5) 📊 Ver status"
    echo "6) 🔧 Reconfigurar"
    echo "7) ❌ Sair"
    echo
    echo -n -e "${YELLOW}Escolha (1-7): ${NC}"
}

show_status() {
    echo -e "${BLUE}📊 Status do Sistema${NC}"
    echo "─────────────────────"
    echo "Email: $EMAIL_USER"
    echo "Servidor: $EMAIL_SERVER:$EMAIL_PORT"
    echo "Sandbox: $SANDBOX_ENABLED"
    [ -d "${BASE_DIR}/data" ] && echo "Dados: ✓" || echo "Dados: ❌"
    [ -d "${BASE_DIR}/logs" ] && echo "Logs: ✓" || echo "Logs: ❌"
    [ -d "${BASE_DIR}/venv" ] && echo "Venv: ✓" || echo "Venv: ❌"
    echo
}

while true; do
    show_menu
    read -r choice
    
    case $choice in
        1)
            "${BASE_DIR}/calma.sh"
            read -p "Enter para continuar..."
            ;;
        2)
            [ ! -d "${BASE_DIR}/venv" ] && python3 -m venv "${BASE_DIR}/venv"
            source "${BASE_DIR}/venv/bin/activate"
            echo -e "${GREEN}Interface: http://localhost:5000${NC}"
            python "${BASE_DIR}/web/app.py"
            ;;
        3)
            "${BASE_DIR}/src/labels.sh"
            read -p "Enter para continuar..."
            ;;
        4)
            echo -n "Intervalo em minutos [5]: "
            read interval
            "${BASE_DIR}/src/cron.sh" ${interval:-5}
            read -p "Enter para continuar..."
            ;;
        5)
            show_status
            read -p "Enter para continuar..."
            ;;
        6)
            "${BASE_DIR}/setup.sh"
            ;;
        7)
            echo -e "${GREEN}👋 Até logo!${NC}"
            exit 0
            ;;
        *)
            echo -e "${RED}Opção inválida!${NC}"
            ;;
    esac
done