#!/usr/bin/env python3
"""
CALMA - Instalador de Dependências Cross-Platform
Funciona em Windows, macOS e Linux
Cria automaticamente um ambiente virtual (venv)
"""

import subprocess
import sys
import os
import platform
import venv

class Colors:
    HEADER = '\033[95m'
    BLUE = '\033[94m'
    CYAN = '\033[96m'
    GREEN = '\033[92m'
    WARNING = '\033[93m'
    FAIL = '\033[91m'
    ENDC = '\033[0m'
    BOLD = '\033[1m'

def supports_color():
    """Verifica se o terminal suporta cores"""
    if platform.system() == 'Windows':
        return os.environ.get('TERM') or os.environ.get('WT_SESSION')
    return hasattr(sys.stdout, 'isatty') and sys.stdout.isatty()

def print_color(text, color):
    """Imprime texto colorido se suportado"""
    if supports_color():
        print(f"{color}{text}{Colors.ENDC}")
    else:
        print(text)

def print_header():
    """Exibe o cabeçalho do instalador"""
    print()
    print_color("=" * 60, Colors.CYAN)
    print_color("   CALMA - Instalador de Dependências", Colors.BOLD)
    print_color("   Sistema: " + platform.system() + " " + platform.release(), Colors.BLUE)
    print_color("   Python: " + sys.version.split()[0], Colors.BLUE)
    print_color("=" * 60, Colors.CYAN)
    print()

def check_python_version():
    """Verifica se a versão do Python é compatível"""
    version = sys.version_info
    if version.major < 3 or (version.major == 3 and version.minor < 8):
        print_color("ERRO: Python 3.8 ou superior é necessário!", Colors.FAIL)
        print_color(f"   Versão atual: {version.major}.{version.minor}.{version.micro}", Colors.WARNING)
        return False
    print_color(f"Python {version.major}.{version.minor}.{version.micro} - OK", Colors.GREEN)
    return True

def check_pip():
    """Verifica se o pip está disponível"""
    try:
        subprocess.run(
            [sys.executable, "-m", "pip", "--version"],
            capture_output=True,
            check=True
        )
        print_color("pip disponível - OK", Colors.GREEN)
        return True
    except subprocess.CalledProcessError:
        print_color("ERRO: pip não está disponível!", Colors.FAIL)
        return False

def get_venv_path():
    """Retorna o caminho do ambiente virtual"""
    base_dir = os.path.dirname(os.path.abspath(__file__))
    return os.path.join(base_dir, "venv")

def get_venv_python():
    """Retorna o caminho do Python no ambiente virtual"""
    venv_path = get_venv_path()
    if platform.system() == "Windows":
        return os.path.join(venv_path, "Scripts", "python.exe")
    return os.path.join(venv_path, "bin", "python3")

def get_venv_pip():
    """Retorna o caminho do pip no ambiente virtual"""
    venv_path = get_venv_path()
    if platform.system() == "Windows":
        return os.path.join(venv_path, "Scripts", "pip.exe")
    return os.path.join(venv_path, "bin", "pip")

def create_virtual_environment():
    """Cria um ambiente virtual para o projeto"""
    venv_path = get_venv_path()
    
    if os.path.exists(venv_path):
        print_color("Ambiente virtual já existe", Colors.GREEN)
        return True
    
    print_color("\nA criar ambiente virtual...", Colors.CYAN)
    
    try:
        venv.create(venv_path, with_pip=True)
        print_color("Ambiente virtual criado em: venv/", Colors.GREEN)
        return True
    except Exception as e:
        print_color(f"ERRO: Não foi possível criar ambiente virtual: {e}", Colors.FAIL)
        return False

def upgrade_pip():
    """Atualiza o pip para a versão mais recente"""
    print_color("\nA atualizar pip...", Colors.CYAN)
    venv_python = get_venv_python()
    try:
        subprocess.run(
            [venv_python, "-m", "pip", "install", "--upgrade", "pip"],
            capture_output=True,
            check=True
        )
        print_color("pip atualizado", Colors.GREEN)
        return True
    except subprocess.CalledProcessError as e:
        print_color("Aviso: Não foi possível atualizar o pip", Colors.WARNING)
        return True

def install_dependencies():
    """Instala as dependências do requirements.txt"""
    requirements_file = os.path.join(os.path.dirname(os.path.abspath(__file__)), "requirements.txt")
    venv_pip = get_venv_pip()
    
    if not os.path.exists(requirements_file):
        print_color("ERRO: Ficheiro requirements.txt não encontrado!", Colors.FAIL)
        return False
    
    print_color("\nA instalar dependências...\n", Colors.CYAN)
    
    with open(requirements_file, 'r') as f:
        deps = [line.strip() for line in f if line.strip() and not line.startswith('#')]
    
    print_color("Dependências a instalar:", Colors.BLUE)
    for dep in deps:
        print(f"   • {dep}")
    print()
    
    try:
        result = subprocess.run(
            [venv_pip, "install", "-r", requirements_file],
            capture_output=False,
            check=True
        )
        print()\n        print_color("Todas as dependências instaladas com sucesso!", Colors.GREEN)
        return True
    except subprocess.CalledProcessError as e:
        print_color("ERRO: Falha ao instalar dependências!", Colors.FAIL)
        return False

def create_directories():
    """Cria as pastas necessárias para o projeto"""
    base_dir = os.path.dirname(os.path.abspath(__file__))
    
    directories = [
        "dados/anexos_processados/a_analisar",
        "dados/anexos_processados/infetados",
        "dados/anexos_processados/limpos",
        "dados/anexos_processados/suspeitos",
        "dados/quarentena",
        "logs",
        "logo",
    ]
    
    print_color("\nA criar estrutura de pastas...", Colors.CYAN)
    
    for dir_path in directories:
        full_path = os.path.join(base_dir, dir_path)
        os.makedirs(full_path, exist_ok=True)
    
    print_color("Estrutura de pastas criada", Colors.GREEN)
    return True

def check_config():
    """Verifica se existe ficheiro de configuração"""
    config_file = os.path.join(os.path.dirname(os.path.abspath(__file__)), "calma_config.json")
    
    if os.path.exists(config_file):
        print_color("Ficheiro de configuração encontrado", Colors.GREEN)
    else:
        print_color("Ficheiro calma_config.json não encontrado", Colors.WARNING)
        print_color("  Execute o programa para criar a configuração inicial", Colors.BLUE)

def verify_installation():
    """Verifica se as dependências foram instaladas corretamente"""
    print_color("\nA verificar instalação...", Colors.CYAN)
    
    venv_python = get_venv_python()
    required_modules = ['flask', 'PIL', 'dotenv']
    all_ok = True
    
    for module in required_modules:
        try:
            result = subprocess.run(
                [venv_python, "-c", f"import {module}"],
                capture_output=True,
                check=True
            )
            print_color(f"   {module}", Colors.GREEN)
        except subprocess.CalledProcessError:
            print_color(f"   {module} - NÃO INSTALADO", Colors.FAIL)
            all_ok = False
    
    return all_ok

def main():
    """Função principal do instalador"""
    print_header()
    
    print_color("A verificar requisitos do sistema...\n", Colors.CYAN)
    
    if not check_python_version():
        sys.exit(1)
    
    if not check_pip():
        sys.exit(1)
    
    if not create_virtual_environment():
        sys.exit(1)
    
    upgrade_pip()
    
    if not install_dependencies():
        sys.exit(1)
    
    create_directories()
    
    check_config()
    
    if verify_installation():
        print()
        print_color("=" * 60, Colors.CYAN)
        print_color("   INSTALAÇÃO CONCLUÍDA COM SUCESSO!", Colors.GREEN + Colors.BOLD)
        print_color("=" * 60, Colors.CYAN)
        print()
        print_color("Para iniciar o CALMA:", Colors.BLUE)
        
        if platform.system() == "Windows":
            print_color("   venv\\Scripts\\python app.py", Colors.CYAN)
        else:
            print_color("   source venv/bin/activate", Colors.CYAN)
            print_color("   python3 app.py", Colors.CYAN)
        
        print()
        print_color("Ou aceda à interface web em:", Colors.BLUE)
        print_color("   http://localhost:5000", Colors.CYAN)
        print()
    else:
        print()
        print_color("Instalação concluída com avisos", Colors.WARNING)
        print_color("  Algumas dependências podem não estar instaladas", Colors.WARNING)
        sys.exit(1)

if __name__ == "__main__":
    main()
