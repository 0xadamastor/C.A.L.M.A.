#!/bin/bash
# CALMA - Aliases universais
# PT: Adicione ao seu .bashrc/.zshrc: source /caminho/para/calma_aliases.sh
# EN: Add to your .bashrc/.zshrc: source /path/to/calma_aliases.sh

# Detecta directoria de instalacao / Detect installation directory
CALMA_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

alias calma='cd "$CALMA_DIR" && ./calma.sh'
alias calma-web='cd "$CALMA_DIR" && python3 scripts/utils/app.py'
alias calma-logs='cd "$CALMA_DIR" && tail -f logs/execucao_*.log 2>/dev/null | head -50'
alias calma-train='cd "$CALMA_DIR" && source venv/bin/activate && python3 scripts/ml/modelo_logistica.py train --balanced'
alias calma-status='cd "$CALMA_DIR" && ./test_compatibility.sh'

echo "[CALMA] Aliases loaded / Atalhos carregados"
echo ""
echo "Available commands / Comandos disponiveis:"
echo "  calma         - Run main system / Executar sistema principal"
echo "  calma-web     - Open web interface / Abrir interface web"
echo "  calma-logs    - View recent logs / Ver logs recentes"
echo "  calma-train   - Retrain ML models / Retreinar modelos ML"
echo "  calma-status  - Check system status / Verificar estado do sistema"
