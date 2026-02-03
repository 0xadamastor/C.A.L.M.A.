#!/usr/bin/env python3
"""
CALMA - Análise Profissional com VirusTotal
Script principal que integra análise VirusTotal + análise local + notificações
"""

import sys
import json
import argparse
from pathlib import Path
from typing import Optional

# Adiciona diretório ao path
SCRIPT_DIR = Path(__file__).parent
sys.path.insert(0, str(SCRIPT_DIR))

from detect_malware_universal import detect_malware, DetectionResult
from notifications import NotificationService


def load_config(config_file: str = None) -> dict:
    """Carrega ficheiro de configuração"""
    if config_file is None:
        config_file = SCRIPT_DIR.parent.parent / "config" / "calma_config.json"
    
    if not Path(config_file).exists():
        print(f"❌ Ficheiro de config não encontrado: {config_file}")
        sys.exit(1)
    
    with open(config_file) as f:
        return json.load(f)


def analyze_and_notify(file_path: str, config_file: str = None, 
                       send_email: bool = True, verbose: bool = False) -> int:
    """
    Analisa ficheiro com VirusTotal e envia notificação
    
    Args:
        file_path: Caminho do ficheiro
        config_file: Ficheiro de configuração
        send_email: Se deve enviar notificação por email
        verbose: Modo verbose
        
    Returns:
        Exit code (0=sucesso, 1=erro)
    """
    
    file_path = Path(file_path)
    
    if not file_path.exists():
        print(f"❌ Ficheiro não encontrado: {file_path}")
        return 1
    
    # Carrega config
    config = load_config(config_file)
    
    print(f"\n{'='*60}")
    print(f"  CALMA - Análise de Malware com VirusTotal")
    print(f"{'='*60}")
    print(f"\n📁 Ficheiro: {file_path.name}")
    print(f"📊 Tamanho: {file_path.stat().st_size / (1024*1024):.2f}MB")
    print(f"\n{'─'*60}\n")
    
    try:
        # Executa detecção (com VirusTotal habilitado)
        use_vt = config.get('virustotal_enabled', False) and config.get('virustotal_api_key', '').lower() != 'your_virustotal_api_key'
        
        if use_vt:
            print("🔍 Iniciando análise via VirusTotal (sandbox em nuvem)...\n")
        else:
            print("🔍 VirusTotal não configurado. Usando análise local...\n")
        
        result = detect_malware(str(file_path), use_virustotal=use_vt, config_file=config_file)
        
        # Exibe resultado
        print(f"\n{'─'*60}\n")
        print(f"✅ ANÁLISE CONCLUÍDA\n")
        
        emoji = "🟢" if result.prediction == "LIMPO" else \
                "🟡" if result.prediction == "SUSPEITO" else "🔴"
        
        print(f"{emoji} Resultado: {result.prediction}")
        print(f"📈 Score: {result.score}/100 ({result.risk_level})")
        print(f"🎯 Método: {result.method}")
        print(f"📊 Probabilidade: {result.probability_malware:.1%}")
        print(f"✨ Confiança: {result.confidence:.1%}")
        print(f"📝 Detalhes: {result.details}")
        
        # Exibe resultado VirusTotal se disponível
        if result.virustotal_result and not result.virustotal_result.error:
            vt = result.virustotal_result
            print(f"\n📋 VirusTotal Detalhes:")
            print(f"   Detecções: {vt.malicious_count}/{vt.total_vendors} antivírus")
            if vt.threat_name:
                print(f"   Ameaça: {vt.threat_name}")
            print(f"   Hash: {vt.file_hash[:32]}...")
        
        # Envia notificação por email
        if send_email and config.get('notifications_enabled', True):
            print(f"\n📧 Enviando notificação por email...")
            
            try:
                notifier = NotificationService(config_file)
                if notifier.send_detection_notification(result, filename=file_path.name):
                    print(f"✅ Notificação enviada com sucesso!")
                else:
                    print(f"⚠️  Notificação não foi enviada (desabilitada para esta classificação)")
            except Exception as e:
                print(f"⚠️  Erro ao enviar notificação: {e}")
        
        print(f"\n{'='*60}\n")
        
        # Return code baseado na classificação
        if result.prediction == "MALWARE":
            return 2  # Malware detectado
        elif result.prediction == "SUSPEITO":
            return 1  # Ficheiro suspeito
        else:
            return 0  # Limpo
    
    except Exception as e:
        print(f"\n❌ Erro na análise: {e}")
        if verbose:
            import traceback
            traceback.print_exc()
        return 1


def main():
    parser = argparse.ArgumentParser(
        description='CALMA - Análise Profissional de Malware com VirusTotal',
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Exemplos:
  %(prog)s ficheiro.exe                  # Analisa ficheiro com notificação
  %(prog)s ficheiro.pdf --no-email       # Analisa sem enviar email
  %(prog)s ficheiro.zip --verbose        # Análise com detalhes
  %(prog)s ficheiro.exe --config config/calma_config.json  # Config customizada
        """
    )
    
    parser.add_argument(
        'file',
        metavar='FICHEIRO',
        help='Ficheiro a analisar'
    )
    
    parser.add_argument(
        '--no-email',
        action='store_true',
        help='Não enviar notificação por email'
    )
    
    parser.add_argument(
        '--config',
        default=None,
        help='Ficheiro de configuração (default: config/calma_config.json)'
    )
    
    parser.add_argument(
        '--verbose',
        action='store_true',
        help='Modo verbose com mais detalhes'
    )
    
    args = parser.parse_args()
    
    # Executa análise
    exit_code = analyze_and_notify(
        args.file,
        config_file=args.config,
        send_email=not args.no_email,
        verbose=args.verbose
    )
    
    sys.exit(exit_code)


if __name__ == '__main__':
    main()
