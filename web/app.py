#!/usr/bin/env python3
"""
CALMA - Sistema Automático de Análise de Anexos
Interface Web para Configuração e Monitorização
"""

from flask import Flask, render_template, request, jsonify, send_file, send_from_directory
from datetime import datetime, timedelta
import json
import os
import subprocess
import shutil
import glob
import re
from pathlib import Path
from functools import wraps
import logging
from dotenv import load_dotenv

# Carregar configurações do arquivo .env
BASE_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))  # Diretório pai (raiz)
ENV_FILE = os.path.join(BASE_DIR, '.env')

if not os.path.exists(ENV_FILE):
    print("❌ Arquivo .env não encontrado!")
    print("Execute './setup.sh' primeiro para configurar o sistema.")
    exit(1)

load_dotenv(ENV_FILE)

app = Flask(__name__, 
           template_folder=os.path.join(BASE_DIR, 'web', 'templates'),
           static_folder=os.path.join(BASE_DIR, 'assets'))

# Usar chave secreta do .env
app.secret_key = os.getenv('FLASK_SECRET_KEY', 'calma-fallback-key')

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

LOGS_DIR = os.path.join(BASE_DIR, 'logs')
DATA_DIR = os.path.join(BASE_DIR, 'data')
LOGO_DIR = os.path.join(BASE_DIR, 'logo')
CONFIG_FILE = os.path.join(BASE_DIR, 'calma_config.json')

os.makedirs(LOGS_DIR, exist_ok=True)
os.makedirs(DATA_DIR, exist_ok=True)

# Carregar defaults do .env
DEFAULT_CONFIG = {
    'email_user': os.getenv('EMAIL_USER', ''),
    'email_pass': os.getenv('EMAIL_PASS', ''),
    'email_server': os.getenv('EMAIL_SERVER', 'imap.gmail.com'),
    'email_port': int(os.getenv('EMAIL_PORT', 993)),
    'sandbox_enabled': os.getenv('SANDBOX_ENABLED', 'false').lower() == 'true',
    'sandbox_url': os.getenv('SANDBOX_URL', 'http://localhost:8090'),
    'sandbox_api_key': os.getenv('SANDBOX_API_KEY', ''),
    'max_file_size': int(os.getenv('MAX_FILE_SIZE', 10485760)),
    'scan_timeout': int(os.getenv('SCAN_TIMEOUT', 300)),
    'hash_algorithm': 'sha256',
    'enable_metadata': True,
    'keep_logs_days': 7,
    'cron_enabled': False,
    'cron_interval': 5,
    'cron_interval_unit': 'minutes',
    'labels': {
        'clean': 'Clean',
        'infected': 'Infected',
        'suspicious': 'Suspicious'
    }
}


def load_config():
    """Carregar configuração do ficheiro JSON"""
    if os.path.exists(CONFIG_FILE):
        try:
            with open(CONFIG_FILE, 'r', encoding='utf-8') as f:
                config = json.load(f)
                return {**DEFAULT_CONFIG, **config}
        except Exception as e:
            logger.error(f"Erro ao carregar config: {e}")
    return DEFAULT_CONFIG.copy()


def save_config(config):
    """Guardar configuração no ficheiro JSON"""
    try:
        with open(CONFIG_FILE, 'w', encoding='utf-8') as f:
            json.dump(config, f, indent=4, ensure_ascii=False)
        return True, "Configuração guardada com sucesso"
    except Exception as e:
        return False, f"Erro ao guardar configuração: {e}"


def get_cron_status():
    """Verificar se o cron job está ativo"""
    try:
        result = subprocess.run(['crontab', '-l'], capture_output=True, text=True)
        if 'calma.sh' in result.stdout:
            return True, "Ativo"
        return False, "Inativo"
    except Exception as e:
        logger.error(f"Erro ao verificar cron: {e}")
        return False, "Erro ao verificar"


def get_service_status():
    """Obter status do serviço"""
    config = load_config()
    cron_enabled, cron_status = get_cron_status()
    
    return {
        'cron_enabled': cron_enabled,
        'cron_status': cron_status,
        'config_loaded': bool(config.get('email_user')),
        'labels_configured': bool(config.get('labels'))
    }


def get_statistics():
    """Obter estatísticas de ficheiros"""
    stats = {
        'clean': 0,
        'infected': 0,
        'suspicious': 0,
        'pending': 0,
        'quarantine': 0,
        'total': 0
    }
    
    try:
        for dir_path, key in [(clean_dir, 'clean'), 
                               (infected_dir, 'infected'),
                               (pending_dir, 'pending')]:
            if os.path.exists(dir_path):
                stats[key] = len([f for f in os.listdir(dir_path) 
                                 if os.path.isfile(os.path.join(dir_path, f)) 
                                 and not f.endswith('.meta')])
        
        if os.path.exists(quarantine_dir):
            quarantine_files = [f for f in os.listdir(quarantine_dir) 
                               if os.path.isfile(os.path.join(quarantine_dir, f)) 
                               and not f.endswith('.meta')]
            stats['quarantine'] = len(quarantine_files)
            stats['suspicious'] = len(quarantine_files)  # Suspicious = Quarantine
        
        stats['total'] = sum(v for k, v in stats.items() if k != 'total')
    except Exception as e:
        logger.error(f"Erro ao obter estatísticas: {e}")
    
    return stats


def get_recent_logs(limit=200):
    """Obter logs recentes APENAS de execução (não Flask/web logs)"""
    all_logs = []
    try:
        log_files = sorted(glob.glob(os.path.join(LOGS_DIR, 'execucao_*.log')), 
                          key=os.path.getmtime, reverse=True)
        
        if not log_files:
            log_files = sorted(glob.glob(os.path.join(LOGS_DIR, '*.log')), 
                              key=os.path.getmtime, reverse=True)
            log_files = [f for f in log_files if not f.endswith('web_') and 'web_' not in f]
        
        for log_file in log_files:
            try:
                with open(log_file, 'r', encoding='utf-8', errors='ignore') as f:
                    lines = f.readlines()
                    all_logs.extend(lines)
            except Exception as e:
                logger.error(f"Erro ao ler {log_file}: {e}")
        
        logs = list(dict.fromkeys(all_logs))
        
        logs = logs[-limit:] if len(logs) > limit else logs
        
        logs = [log.strip() for log in logs if log.strip()]
    except Exception as e:
        logger.error(f"Erro ao obter logs: {e}")
        logs = []
    
    return logs


def get_recent_analyses(limit=50):
    """Obter análises estruturadas recentes (classificações de ficheiros)"""
    analyses = []
    try:
        logs = get_recent_logs(500)
        
        for log in logs:
            if 'Classificado:' in log:
                try:
                    timestamp_match = re.search(r'\[(\d{4}-\d{2}-\d{2}\s\d{2}:\d{2}:\d{2})\]', log)
                    filename_match = re.search(r'Classificado:\s*([^\s]+)', log)
                    status_match = re.search(r'Classificado:.*->\s*(\w+)\s*\(', log)
                    score_match = re.search(r'Score:\s*(\d+)', log)
                    
                    if filename_match:
                        timestamp = timestamp_match.group(1) if timestamp_match else 'N/A'
                        filename = filename_match.group(1)
                        status = status_match.group(1) if status_match else 'UNKNOWN'
                        score = score_match.group(1) if score_match else '0'
                        
                        analyses.append({
                            'timestamp': timestamp,
                            'filename': filename,
                            'status': status,
                            'score': int(score),
                            'verdict': 'Malicious' if status == 'INFETADO' else ('Suspicious' if status == 'SUSPEITO' else 'Clean')
                        })
                except Exception as e:
                    logger.debug(f"Erro ao parsear log: {e}")
                    
    except Exception as e:
        logger.error(f"Erro ao obter análises: {e}")
    
    return analyses[-limit:] if len(analyses) > limit else analyses


@app.route('/logo/<filename>')
def serve_logo(filename):
    """Servir ficheiros da pasta logo"""
    try:
        return send_from_directory(LOGO_DIR, filename)
    except Exception as e:
        logger.error(f"Erro ao servir logo: {e}")
        return jsonify({'error': 'Logo not found'}), 404

@app.route('/')
def index():
    """Dashboard principal"""
    config = load_config()
    stats = get_statistics()
    service_status = get_service_status()
    
    return render_template('index.html',
                         config=config,
                         stats=stats,
                         service_status=service_status)



@app.route('/api/config', methods=['GET', 'POST'])
def api_config():
    """API para obter/salvar configuração"""
    if request.method == 'GET':
        config = load_config()
        config['email_pass'] = '••••••••' if config.get('email_pass') else ''
        config['sandbox_api_key'] = '••••••••' if config.get('sandbox_api_key') else ''
        return jsonify(config)
    
    elif request.method == 'POST':
        try:
            data = request.get_json()
            config = load_config()
            
            for key in data:
                if key not in ['email_pass', 'sandbox_api_key'] or data[key] != '••••••••':
                    config[key] = data[key]
                else:
                    if not data[key].startswith('•'):
                        config[key] = data[key]
            
            success, message = save_config(config)
            
            if success:
                update_calma_script(config)
            
            return jsonify({'success': success, 'message': message}), 200 if success else 400
        except Exception as e:
            return jsonify({'success': False, 'message': str(e)}), 400


@app.route('/api/stats', methods=['GET'])
def api_stats():
    """API para obter estatísticas"""
    stats = get_statistics()
    return jsonify(stats)


@app.route('/api/status', methods=['GET'])
def api_status():
    """API para obter status do serviço"""
    status = get_service_status()
    status['stats'] = get_statistics()
    return jsonify(status)


@app.route('/api/logs', methods=['GET'])
def api_logs():
    """API para obter logs recentes"""
    limit = request.args.get('lines', request.args.get('limit', 200, type=int), type=int)
    logs = get_recent_logs(limit)
    return jsonify({'logs': logs})


@app.route('/api/analyses', methods=['GET'])
def api_analyses():
    """API para obter análises estruturadas recentes"""
    limit = request.args.get('limit', 50, type=int)
    analyses = get_recent_analyses(limit)
    return jsonify({'analyses': analyses})


@app.route('/api/cron/enable', methods=['POST'])
def api_cron_enable():
    """Ativar cron job com intervalo customizável"""
    try:
        config = load_config()
        data = request.get_json()
        interval = data.get('interval', 5)
        interval_unit = data.get('interval_unit', 'minutes')
        
        script_path = os.path.join(BASE_DIR, 'calma.sh')
        cron_log = os.path.join(LOGS_DIR, 'cron.log')
        
        # Converter unidade para expressão cron apropriada
        if interval_unit == 'seconds':
            # Para segundos, usar: */N * * * * * (6 campos para suportar segundos)
            # Nota: Nem todos os cron suportam, pode ser */1 * * * *
            cron_entry = f"*/{interval} * * * * cd {BASE_DIR} && ./calma.sh >> {cron_log} 2>&1"
        elif interval_unit == 'hours':
            # Para horas: 0 */N * * * (a cada N horas no minuto 0)
            cron_entry = f"0 */{interval} * * * cd {BASE_DIR} && ./calma.sh >> {cron_log} 2>&1"
        else:  # minutes (padrão)
            # Para minutos: */N * * * *
            cron_entry = f"*/{interval} * * * * cd {BASE_DIR} && ./calma.sh >> {cron_log} 2>&1"
        
        # Remover entrada antiga se existir
        try:
            result = subprocess.run(['crontab', '-l'], capture_output=True, text=True)
            crontab_content = result.stdout
        except:
            crontab_content = ""
        
        # Filtrar linhas antigas
        lines = [line for line in crontab_content.split('\n') if 'calma.sh' not in line]
        lines.append(cron_entry)
        
        # Escrever novo crontab
        new_crontab = '\n'.join(lines) + '\n'
        process = subprocess.Popen(['crontab', '-'], stdin=subprocess.PIPE, 
                                  stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
        stdout, stderr = process.communicate(input=new_crontab)
        
        if process.returncode == 0:
            config['cron_enabled'] = True
            config['cron_interval'] = interval
            config['cron_interval_unit'] = interval_unit
            save_config(config)
            return jsonify({'success': True, 'message': f'Cron job ativado a cada {interval} {interval_unit}'})
        else:
            return jsonify({'success': False, 'message': f'Erro: {stderr}'}), 400
    except Exception as e:
        return jsonify({'success': False, 'message': str(e)}), 400


@app.route('/api/cron/disable', methods=['POST'])
def api_cron_disable():
    """Desativar cron job"""
    try:
        config = load_config()
        
        result = subprocess.run(['crontab', '-l'], capture_output=True, text=True)
        crontab_content = result.stdout
        
        lines = [line for line in crontab_content.split('\n') if 'calma.sh' not in line]
        new_crontab = '\n'.join(lines) + '\n'
        
        process = subprocess.Popen(['crontab', '-'], stdin=subprocess.PIPE,
                                  stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
        stdout, stderr = process.communicate(input=new_crontab)
        
        if process.returncode == 0:
            config['cron_enabled'] = False
            save_config(config)
            return jsonify({'success': True, 'message': 'Cron job desativado'})
        else:
            return jsonify({'success': False, 'message': f'Erro: {stderr}'}), 400
    except Exception as e:
        return jsonify({'success': False, 'message': str(e)}), 400


@app.route('/api/run', methods=['POST'])
def api_run():
    """Executar o script calma.sh manualmente"""
    try:
        script_path = os.path.join(BASE_DIR, 'calma.sh')
        if not os.path.exists(script_path):
            return jsonify({'success': False, 'message': 'Script calma.sh não encontrado'}), 400
        
        os.chmod(script_path, 0o755)
        
        log_file = os.path.join(LOGS_DIR, f'manual_run_{datetime.now().strftime("%Y%m%d_%H%M%S")}.log')
        with open(log_file, 'w') as f:
            subprocess.Popen([script_path], stdout=f, stderr=subprocess.STDOUT, cwd=BASE_DIR)
        
        return jsonify({'success': True, 'message': 'Script iniciado em background', 'log': log_file})
    except Exception as e:
        return jsonify({'success': False, 'message': str(e)}), 400


@app.route('/api/logs/clear', methods=['POST'])
def api_logs_clear():
    """Limpar logs"""
    try:
        days = request.get_json().get('days', 7)
        
        now = datetime.now()
        cutoff_time = (now - timedelta(days=days)).timestamp()
        
        count = 0
        for log_file in glob.glob(os.path.join(LOGS_DIR, '*')):
            if os.path.getmtime(log_file) < cutoff_time:
                try:
                    if os.path.isfile(log_file):
                        os.remove(log_file)
                        count += 1
                except:
                    pass
        
        return jsonify({'success': True, 'message': f'{count} ficheiros eliminados'})
    except Exception as e:
        return jsonify({'success': False, 'message': str(e)}), 400


@app.route('/api/test-connection', methods=['POST'])
def api_test_connection():
    """Testar conexão com Gmail"""
    try:
        import imaplib
        data = request.get_json()
        email = data.get('email')
        password = data.get('password')
        
        if not email or not password or password.startswith('•'):
            return jsonify({'success': False, 'message': 'Email e password obrigatórios'}), 400
        
        mail = imaplib.IMAP4_SSL('imap.gmail.com', 993)
        mail.login(email, password)
        mail.logout()
        
        return jsonify({'success': True, 'message': 'Conexão estabelecida com sucesso!'})
    except imaplib.IMAP4.error as e:
        return jsonify({'success': False, 'message': f'Erro de autenticação: {str(e)}'}), 400
    except Exception as e:
        return jsonify({'success': False, 'message': f'Erro na conexão: {str(e)}'}), 400


def update_calma_script(config):
    """Atualizar calma.sh com a nova configuração"""
    try:
        with open(script_path, 'r', encoding='utf-8') as f:
            content = f.read()
        
        replacements = {
            'EMAIL_USER="[^"]*"': f'EMAIL_USER="{config.get("email_user", "")}"',
            'EMAIL_PASS="[^"]*"': f'EMAIL_PASS="{config.get("email_pass", "")}"',
            'EMAIL_SERVER="[^"]*"': f'EMAIL_SERVER="{config.get("email_server", "imap.gmail.com")}"',
            'EMAIL_PORT="[^"]*"': f'EMAIL_PORT="{config.get("email_port", "993")}"',
            'SANDBOX_ENABLED="[^"]*"': f'SANDBOX_ENABLED="{str(config.get("sandbox_enabled", False)).lower()}"',
            'SANDBOX_URL="[^"]*"': f'SANDBOX_URL="{config.get("sandbox_url", "")}"',
            'SANDBOX_API_KEY="[^"]*"': f'SANDBOX_API_KEY="{config.get("sandbox_api_key", "")}"',
            'MAX_FILE_SIZE="[^"]*"': f'MAX_FILE_SIZE="{config.get("max_file_size", "10485760")}"',
            'SCAN_TIMEOUT="[^"]*"': f'SCAN_TIMEOUT="{config.get("scan_timeout", "300")}"',
            'KEEP_LOGS_DAYS="[^"]*"': f'KEEP_LOGS_DAYS="{config.get("keep_logs_days", "7")}"',
            'HASH_ALGORITHM="[^"]*"': f'HASH_ALGORITHM="{config.get("hash_algorithm", "sha256")}"',
            'ENABLE_METADATA="[^"]*"': f'ENABLE_METADATA="{str(config.get("enable_metadata", True)).lower()}"',
        }
        
        for pattern, replacement in replacements.items():
            content = re.sub(pattern, replacement, content)
        
        with open(script_path, 'w', encoding='utf-8') as f:
            f.write(content)
        
        return True
    except Exception as e:
        logger.error(f"Erro ao atualizar calma.sh: {e}")
        return False


if __name__ == '__main__':
    app.run(debug=True, host='0.0.0.0', port=5000)
