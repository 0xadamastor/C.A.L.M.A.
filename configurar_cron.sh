#!/bin/bash

echo "Configurando cron job para calma.sh"
echo ""

INTERVALO="${1:-5}"

CALMA_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CALMA_SCRIPT="${CALMA_DIR}/calma.sh"
CRON_LOG="${CALMA_DIR}/logs/cron.log"

echo "Directório: $CALMA_DIR"
echo "Script: $CALMA_SCRIPT"
echo "Log: $CRON_LOG"
echo "Intervalo: A cada $INTERVALO minutos"
echo ""

if [ ! -f "$CALMA_SCRIPT" ]; then
    echo "Erro: Script $CALMA_SCRIPT não encontrado!"
    exit 1
fi

CRON_ENTRY="*/$INTERVALO * * * * cd $CALMA_DIR && ./calma.sh >> $CRON_LOG 2>&1"

echo "Entrada do cron a adicionar:"
echo "   $CRON_ENTRY"
echo ""

(crontab -l 2>/dev/null | grep -v "calma.sh"; echo "$CRON_ENTRY") | crontab -

if [ $? -eq 0 ]; then
    echo "Cron job configurado com sucesso!"
    echo ""
    echo "Crontab actual:"
    crontab -l | grep calma
    echo ""
    echo "Para verificar os logs:"
    echo "   tail -f $CRON_LOG"
    echo ""
    echo "Para remover o cron job:"
    echo "   crontab -e"
    echo "   (e remova a linha com calma.sh)"
else
    echo "Erro ao configurar o cron job!"
    exit 1
fi
