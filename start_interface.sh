#!/bin/bash

# CALMA - Script de Inicialização da Interface Web
# Inicia o dashboard web da aplicação Calma

set -e

BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
VENV_DIR="${BASE_DIR}/venv"
LOGS_DIR="${BASE_DIR}/logs"
PORT="${1:-5000}"

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Criar diretórios
mkdir -p "$LOGS_DIR"

# Banner
echo ""
echo -e "${BLUE}╔════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║     CALMA - Interface de Controlo     ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════╝${NC}"
echo ""

# Verificar Python
if ! command -v python3 &> /dev/null; then
    echo -e "${RED}✗ Python3 não encontrado!${NC}"
    echo "Por favor instale Python 3.7 ou superior"
    exit 1
fi

echo -e "${GREEN}✓ Python encontrado: $(python3 --version)${NC}"
echo ""

# Criar virtual environment se não existir
if [ ! -d "$VENV_DIR" ]; then
    echo -e "${YELLOW}⚙️  Criando ambiente virtual...${NC}"
    python3 -m venv "$VENV_DIR"
    echo -e "${GREEN}✓ Ambiente virtual criado${NC}"
fi

# Ativar virtual environment
source "$VENV_DIR/bin/activate"
echo -e "${GREEN}✓ Ambiente virtual ativado${NC}"

# Instalar dependências
echo ""
echo -e "${YELLOW}⚙️  Instalando dependências...${NC}"
pip install --quiet --upgrade pip setuptools wheel
pip install --quiet flask

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ Dependências instaladas${NC}"
else
    echo -e "${RED}✗ Erro ao instalar dependências${NC}"
    exit 1
fi

# Verificar se calma.sh existe
if [ ! -f "$BASE_DIR/calma.sh" ]; then
    echo -e "${RED}✗ Script calma.sh não encontrado em $BASE_DIR${NC}"
    exit 1
fi

echo -e "${GREEN}✓ Script calma.sh encontrado${NC}"

# Tornar executável
chmod +x "$BASE_DIR/calma.sh"

echo ""
echo -e "${BLUE}════════════════════════════════════════${NC}"
echo -e "${GREEN}✓ Configuração concluída!${NC}"
echo -e "${BLUE}════════════════════════════════════════${NC}"
echo ""
echo -e "${YELLOW}🚀 Iniciando servidor na porta $PORT...${NC}"
echo ""
echo -e "${GREEN}➜ Abra o navegador e aceda a:${NC}"
echo -e "${BLUE}   http://localhost:$PORT${NC}"
echo ""
echo -e "${YELLOW}Pressione CTRL+C para parar o servidor${NC}"
echo ""

# Iniciar aplicação Flask
cd "$BASE_DIR"
python3 app.py --host=0.0.0.0 --port=$PORT 2>&1 | tee -a "$LOGS_DIR/web_$(date +%Y%m%d_%H%M%S).log"
