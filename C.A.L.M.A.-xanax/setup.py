#!/usr/bin/env python3
"""
CALMA - Interactive Setup
"""

import os
import sys
import json
import shutil
from pathlib import Path

# Colors
class Colors:
    CYAN = '\033[96m'
    GREEN = '\033[92m'
    YELLOW = '\033[93m'
    RED = '\033[91m'
    BOLD = '\033[1m'
    END = '\033[0m'

# Language strings
LANG = {}

STRINGS = {
    'en': {
        'welcome': 'Welcome to CALMA Setup Wizard!',
        'subtitle': 'Setup Wizard',
        'press_enter': 'Press Enter to continue...',
        'step': 'Step',
        'of': 'of',
        'checking_requirements': 'Checking Requirements',
        'python_ok': 'Python',
        'python_required': 'Python 3.8+ required',
        'jq_ok': 'jq installed',
        'jq_missing': 'jq not found (required for bash scripts)',
        'venv_ok': 'Virtual environment exists',
        'venv_missing': 'Virtual environment not found',
        'venv_hint': 'Run: python install_universal.py',
        'requirements_missing': 'Some requirements are missing.',
        'run_install_first': 'Run install_universal.py first if you haven\'t.',
        'continue_anyway': 'Continue anyway?',
        'setup_cancelled': 'Setup cancelled.',
        'gmail_config': 'Gmail Configuration',
        'gmail_intro': '''
    CALMA needs Gmail credentials to monitor email attachments.
    
    Requirements:
    1. Gmail account with 2FA enabled
    2. App Password (not your main password)
    
    How to get App Password:
    1. Go to: https://myaccount.google.com/apppasswords
    2. Create new app password
    3. Copy the 16-character code
''',
        'enter_email': 'Enter your Gmail address:',
        'enter_password': 'Enter your App Password (16 characters):',
        'vt_config': 'VirusTotal Integration (Optional)',
        'vt_intro': '''
    VirusTotal provides cloud-based malware analysis.
    Free tier includes 500 lookups/day.
    
    Get your API key at:
    https://www.virustotal.com/gui/my-apikey
''',
        'enable_vt': 'Enable VirusTotal integration?',
        'enter_vt_key': 'Enter your VirusTotal API key:',
        'labels_config': 'Gmail Labels',
        'labels_intro': '''
    CALMA will create these labels in your Gmail:
    
    - Clean     : Safe attachments
    - Suspicious: Possible threats
    - Infected  : Confirmed malware
''',
        'use_default_labels': 'Use default label names?',
        'label_clean': 'Label for clean files:',
        'label_suspicious': 'Label for suspicious files:',
        'label_infected': 'Label for infected files:',
        'saving_config': 'Saving Configuration',
        'backup_created': 'Backup created at:',
        'config_saved': 'Configuration saved',
        'permissions_set': 'Permissions set to 600',
        'setup_complete': 'Setup Complete!',
        'next_steps': '''
    Next steps:
    
    1. Test the installation:
       ./test_compatibility.sh
    
    2. Run CALMA:
       ./calma.sh
    
    3. Or use the web interface:
       python3 scripts/utils/app.py
       Open: http://localhost:5000
    
    4. For aliases, add to your shell config:
       source calma_aliases.sh
''',
        'email_required': 'Email and password are required!',
        'run_again': 'Please run setup again with valid credentials.',
        'yes_no_default_y': 'Y/n',
        'yes_no_default_n': 'y/N',
    },
    'pt': {
        'welcome': 'Bem-vindo ao Assistente de Configuracao CALMA!',
        'subtitle': 'Assistente de Configuracao',
        'press_enter': 'Prima Enter para continuar...',
        'step': 'Passo',
        'of': 'de',
        'checking_requirements': 'Verificar Requisitos',
        'python_ok': 'Python',
        'python_required': 'Python 3.8+ necessario',
        'jq_ok': 'jq instalado',
        'jq_missing': 'jq nao encontrado (necessario para scripts bash)',
        'venv_ok': 'Ambiente virtual existe',
        'venv_missing': 'Ambiente virtual nao encontrado',
        'venv_hint': 'Execute: python install_universal.py',
        'requirements_missing': 'Alguns requisitos estao em falta.',
        'run_install_first': 'Execute install_universal.py primeiro.',
        'continue_anyway': 'Continuar mesmo assim?',
        'setup_cancelled': 'Configuracao cancelada.',
        'gmail_config': 'Configuracao Gmail',
        'gmail_intro': '''
    CALMA precisa de credenciais Gmail para monitorizar anexos.
    
    Requisitos:
    1. Conta Gmail com 2FA activo
    2. App Password (nao a senha principal)
    
    Como obter App Password:
    1. Ir a: https://myaccount.google.com/apppasswords
    2. Criar nova app password
    3. Copiar o codigo de 16 caracteres
''',
        'enter_email': 'Introduza o seu endereco Gmail:',
        'enter_password': 'Introduza a App Password (16 caracteres):',
        'vt_config': 'Integracao VirusTotal (Opcional)',
        'vt_intro': '''
    VirusTotal fornece analise de malware na cloud.
    O nivel gratuito inclui 500 consultas/dia.
    
    Obtenha a sua chave API em:
    https://www.virustotal.com/gui/my-apikey
''',
        'enable_vt': 'Activar integracao VirusTotal?',
        'enter_vt_key': 'Introduza a sua chave API VirusTotal:',
        'labels_config': 'Etiquetas Gmail',
        'labels_intro': '''
    CALMA vai criar estas etiquetas no seu Gmail:
    
    - Clean     : Anexos seguros
    - Suspicious: Possiveis ameacas
    - Infected  : Malware confirmado
''',
        'use_default_labels': 'Usar nomes de etiquetas por defeito?',
        'label_clean': 'Etiqueta para ficheiros limpos:',
        'label_suspicious': 'Etiqueta para ficheiros suspeitos:',
        'label_infected': 'Etiqueta para ficheiros infectados:',
        'saving_config': 'Guardar Configuracao',
        'backup_created': 'Backup criado em:',
        'config_saved': 'Configuracao guardada',
        'permissions_set': 'Permissoes definidas para 600',
        'setup_complete': 'Configuracao Completa!',
        'next_steps': '''
    Proximos passos:
    
    1. Testar a instalacao:
       ./test_compatibility.sh
    
    2. Executar CALMA:
       ./calma.sh
    
    3. Ou usar a interface web:
       python3 scripts/utils/app.py
       Abrir: http://localhost:5000
    
    4. Para aliases, adicionar ao shell:
       source calma_aliases.sh
''',
        'email_required': 'Email e password sao obrigatorios!',
        'run_again': 'Execute o setup novamente com credenciais validas.',
        'yes_no_default_y': 'S/n',
        'yes_no_default_n': 's/N',
    }
}

def t(key):
    """Get translated string"""
    return LANG.get(key, key)

def c(text, color):
    """Apply color to text"""
    return f"{color}{text}{Colors.END}"

def clear_screen():
    os.system('cls' if os.name == 'nt' else 'clear')

def print_header():
    clear_screen()
    print(c(f"""
    ╔═══════════════════════════════════════════════════════════╗
    ║   ██████╗ █████╗ ██╗     ███╗   ███╗ █████╗               ║
    ║  ██╔════╝██╔══██╗██║     ████╗ ████║██╔══██╗              ║
    ║  ██║     ███████║██║     ██╔████╔██║███████║              ║
    ║  ██║     ██╔══██║██║     ██║╚██╔╝██║██╔══██║              ║
    ║  ╚██████╗██║  ██║███████╗██║ ╚═╝ ██║██║  ██║              ║
    ║   ╚═════╝╚═╝  ╚═╝╚══════╝╚═╝     ╚═╝╚═╝  ╚═╝              ║
    ║                                                           ║
    ║           {t('subtitle'):^43}    ║
    ╚═══════════════════════════════════════════════════════════╝
    """, Colors.CYAN))

def print_step(num, total, title):
    step_text = t("step")
    of_text = t("of")
    print(f"\n{c(f'[{step_text} {num} {of_text} {total}]', Colors.BOLD)} {title}")
    print("─" * 60)

def ask_yes_no(question, default=True):
    """Ask a yes/no question"""
    default_str = t('yes_no_default_y') if default else t('yes_no_default_n')
    print(f"\n{question}")
    answer = input(f"  [{default_str}]: ").strip().lower()
    
    if not answer:
        return default
    return answer in ['y', 'yes', 's', 'sim']

def ask_input(question, default="", password=False):
    """Ask for input"""
    print(f"\n{question}")
    
    if password:
        import getpass
        try:
            value = getpass.getpass(f"  [{default or '****'}]: ")
        except:
            value = input(f"  [{default or '****'}]: ")
    else:
        value = input(f"  [{default}]: ").strip()
    
    return value if value else default

def select_language():
    """Ask user to select language"""
    clear_screen()
    print(c("""
    ╔═══════════════════════════════════════════════════════════╗
    ║   ██████╗ █████╗ ██╗     ███╗   ███╗ █████╗               ║
    ║  ██╔════╝██╔══██╗██║     ████╗ ████║██╔══██╗              ║
    ║  ██║     ███████║██║     ██╔████╔██║███████║              ║
    ║  ██║     ██╔══██║██║     ██║╚██╔╝██║██╔══██║              ║
    ║  ╚██████╗██║  ██║███████╗██║ ╚═╝ ██║██║  ██║              ║
    ║   ╚═════╝╚═╝  ╚═╝╚══════╝╚═╝     ╚═╝╚═╝  ╚═╝              ║
    ╚═══════════════════════════════════════════════════════════╝
    """, Colors.CYAN))
    
    print(f"""
    Select language / Selecione o idioma:
    
    {c('[1]', Colors.GREEN)} English
    {c('[2]', Colors.GREEN)} Portugues
    """)
    
    choice = input("  [1/2]: ").strip()
    
    if choice == '2':
        return 'pt'
    return 'en'

def check_requirements():
    """Check system requirements"""
    print_step(1, 5, t('checking_requirements'))
    
    issues = []
    
    # Python version
    if sys.version_info >= (3, 8):
        print(f"  {c('[OK]', Colors.GREEN)} {t('python_ok')} {sys.version_info.major}.{sys.version_info.minor}")
    else:
        print(f"  {c('[!]', Colors.RED)} {t('python_required')}")
        issues.append("Python")
    
    # jq
    if shutil.which('jq'):
        print(f"  {c('[OK]', Colors.GREEN)} {t('jq_ok')}")
    else:
        print(f"  {c('[!]', Colors.YELLOW)} {t('jq_missing')}")
        issues.append("jq")
    
    # Virtual environment
    venv_path = Path(__file__).parent / 'venv'
    if venv_path.exists():
        print(f"  {c('[OK]', Colors.GREEN)} {t('venv_ok')}")
    else:
        print(f"  {c('[!]', Colors.YELLOW)} {t('venv_missing')}")
        print(f"      {t('venv_hint')}")
        issues.append("venv")
    
    return len(issues) == 0

def setup_gmail():
    """Setup Gmail configuration"""
    print_step(2, 5, t('gmail_config'))
    print(t('gmail_intro'))
    
    email = ask_input(t('enter_email'), "")
    password = ask_input(t('enter_password'), "", password=True)
    
    return email, password

def setup_virustotal():
    """Setup VirusTotal (optional)"""
    print_step(3, 5, t('vt_config'))
    print(t('vt_intro'))
    
    use_vt = ask_yes_no(t('enable_vt'), default=False)
    
    if use_vt:
        api_key = ask_input(t('enter_vt_key'), "")
        return True, api_key
    
    return False, ""

def setup_labels():
    """Setup Gmail labels"""
    print_step(4, 5, t('labels_config'))
    print(t('labels_intro'))
    
    use_default = ask_yes_no(t('use_default_labels'), default=True)
    
    if use_default:
        return "Clean", "Suspicious", "Infected"
    
    clean = ask_input(t('label_clean'), "Clean")
    suspicious = ask_input(t('label_suspicious'), "Suspicious")
    infected = ask_input(t('label_infected'), "Infected")
    
    return clean, suspicious, infected

def save_config(email, password, vt_enabled, vt_key, labels):
    """Save configuration file"""
    print_step(5, 5, t('saving_config'))
    
    base_dir = Path(__file__).parent
    config_file = base_dir / 'config' / 'calma_config.json'
    
    config = {
        "email_user": email,
        "email_pass": password,
        "email_server": "imap.gmail.com",
        "email_port": 993,
        "max_file_size": 10485760,
        "scan_timeout": 300,
        "hash_algorithm": "sha256",
        "enable_metadata": True,
        "keep_logs_days": 7,
        "cron_enabled": False,
        "cron_interval": 3,
        "cron_interval_unit": "hours",
        "virustotal_api_key": vt_key if vt_key else "your_virustotal_api_key",
        "virustotal_enabled": vt_enabled,
        "virustotal_timeout": 300,
        "fallback_to_local": True,
        "notifications_enabled": True,
        "labels": {
            "clean": labels[0],
            "infected": labels[2],
            "suspicious": labels[1]
        }
    }
    
    # Backup existing config
    if config_file.exists():
        backup_file = config_file.with_suffix('.json.backup')
        shutil.copy(config_file, backup_file)
        print(f"  {t('backup_created')} {backup_file.name}")
    
    # Save new config
    with open(config_file, 'w', encoding='utf-8') as f:
        json.dump(config, f, indent=4, ensure_ascii=False)
    
    print(f"  {c('[OK]', Colors.GREEN)} {t('config_saved')}")
    
    # Set permissions (Unix only)
    if os.name != 'nt':
        os.chmod(config_file, 0o600)
        print(f"  {c('[OK]', Colors.GREEN)} {t('permissions_set')}")

def print_next_steps():
    """Print next steps"""
    print(c(f"""
    ╔═══════════════════════════════════════════════════════════╗
    ║                    {t('setup_complete'):^37} ║
    ╚═══════════════════════════════════════════════════════════╝
    """, Colors.GREEN))
    
    print(t('next_steps'))

def main():
    global LANG
    
    # Select language first
    lang_code = select_language()
    LANG = STRINGS[lang_code]
    
    # Welcome
    print_header()
    print(f"\n    {t('welcome')}\n")
    input(f"    {t('press_enter')}")
    
    # Step 1: Check requirements
    print_header()
    if not check_requirements():
        print(f"\n{c('[!]', Colors.YELLOW)} {t('requirements_missing')}")
        print(f"    {t('run_install_first')}")
        if not ask_yes_no(t('continue_anyway'), default=False):
            print(f"\n{t('setup_cancelled')}")
            sys.exit(1)
    
    input(f"\n    {t('press_enter')}")
    
    # Step 2: Gmail setup
    print_header()
    email, password = setup_gmail()
    
    # Step 3: VirusTotal setup
    print_header()
    vt_enabled, vt_key = setup_virustotal()
    
    # Step 4: Labels setup
    print_header()
    labels = setup_labels()
    
    # Step 5: Save configuration
    print_header()
    
    if not email or not password:
        print(f"\n{c('[!]', Colors.RED)} {t('email_required')}")
        print(f"    {t('run_again')}")
        sys.exit(1)
    
    save_config(email, password, vt_enabled, vt_key, labels)
    
    # Final steps
    print_header()
    print_next_steps()

if __name__ == '__main__':
    try:
        main()
    except KeyboardInterrupt:
        print(f"\n\n{Colors.YELLOW}Cancelled / Cancelado{Colors.END}")
        sys.exit(0)
    except Exception as e:
        print(f"\n{Colors.RED}Error: {e}{Colors.END}")
        sys.exit(1)
