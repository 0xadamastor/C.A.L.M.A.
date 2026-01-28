#!/bin/bash
# CALMA - Instalador de Dependências para Linux/macOS
# Execute este script para instalar todas as dependências

# Cores
RED='\033[0;31m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

echo ""
echo -e "${CYAN}==========================================${NC}"
echo -e "${CYAN}   CALMA - Instalador de Dependências${NC}"
echo -e "${CYAN}==========================================${NC}"
echo ""

# Diretório do script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Verificar se Python está instalado
if command -v python3 &> /dev/null; then
    PYTHON_CMD="python3"
elif command -v python &> /dev/null; then
    PYTHON_CMD="python"
else
    echo -e "${RED}[ERRO] Python não encontrado!${NC}"
    echo ""
    echo "Por favor, instale Python 3.8 ou superior:"
    echo ""
    if [[ "$OSTYPE" == "darwin"* ]]; then
        echo "  macOS: brew install python3"
        echo "  ou: https://www.python.org/downloads/"
    else
        echo "  Ubuntu/Debian: sudo apt install python3 python3-pip"
        echo "  Fedora: sudo dnf install python3 python3-pip"
        echo "  Arch: sudo pacman -S python python-pip"
    fi
    echo ""
    exit 1
fi

# Executar o instalador Python
echo "A iniciar instalação..."
echo ""
$PYTHON_CMD "$SCRIPT_DIR/install.py"

exit_code=$?

if [ $exit_code -ne 0 ]; then
    echo ""
    echo -e "${RED}[ERRO] A instalação falhou!${NC}"
    exit 1
fi

echo ""
