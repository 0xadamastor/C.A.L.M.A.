# CALMA - Containerized Automated Lazy Mail Anti-nasties

```
  █████╗ █████╗ ██╗     ███╗   ███╗ █████╗
██╔════╝██╔══██╗██║     ████╗ ████║██╔══██╗
██║     ███████║██║     ██╔████╔██║███████║
██║     ██╔══██║██║     ██║╚██╔╝██║██╔══██║
╚██████╗██║  ██║███████╗██║ ╚═╝ ██║██║  ██║
 ╚═════╝╚═╝  ╚═╝╚══════╝╚═╝     ╚═╝╚═╝  ╚═╝
```

---

## 🇬🇧 English | 🇵🇹 Português

**Choose your language / Escolhe o teu idioma:**

- [🇬🇧 **English Documentation**](#-english-documentation)
- [🇵🇹 **Documentação em Português**](#-documentação-em-português)

---

# 🇬🇧 English Documentation

**CALMA** monitors email attachments and classifies them by risk level using machine learning. Safe, isolated, and cross-platform.

### Features

- **Cross-platform:** Linux, macOS, Windows (Git Bash/WSL)
- **Machine Learning:** PE and PDF analysis models
- **Gmail integration:** automatic labeling (Clean/Suspicious/Infected)
- **VirusTotal integration:** optional cloud sandbox analysis
- **Web dashboard:** monitoring and configuration interface

### Quick Start

```bash
# Clone repository
git clone <repo-url> calma
cd calma

# Linux/macOS
./install_universal.sh

# Windows
python install_universal.py

# Interactive setup (recommended)
python setup.py

# Run
./calma.sh
```

---

## How to Start

### First-Time Setup

#### Step 1: Install Dependencies

**Windows:**
```bash
# Use PowerShell or Command Prompt
python install_universal.py
```

Or just run the `install_universal.bat`

**Linux/macOS:**
```bash
# Make install script executable
chmod +x install_universal.sh

# Run installation
./install_universal.sh
```

**What this does:**
- ✓ Checks Python 3.8+ is installed
- ✓ Installs system dependencies (jq, etc.)
- ✓ Creates virtual environment
- ✓ Installs Python packages
- ✓ Creates directory structure
- ✓ Creates default config file

#### Step 2: Configure Gmail

**Option A: Interactive Setup (Recommended)**
```bash
python setup.py
```

The wizard guides you through:
1. Language selection (English/Portuguese)
2. Requirements check
3. Gmail credentials (email + app password)
4. VirusTotal API key (optional)
5. Gmail labels configuration
6. Malware Bazar test sender (optional)

**Option B: Manual Configuration**
```bash
# Copy example config
cp config/calma_config.example.json config/calma_config.json

# Edit with your credentials
nano config/calma_config.json  # Linux/macOS
notepad config/calma_config.json  # Windows
```

**Required Gmail Setup:**
1. Enable 2FA on your Gmail account
2. Generate App Password at: https://myaccount.google.com/apppasswords
3. Use the app password (not your regular password) in config

#### Step 3: Setup Shell Aliases (Optional)

**Linux/macOS:**
```bash
# Add to ~/.bashrc or ~/.zshrc
echo "source $(pwd)/calma_aliases.sh" >> ~/.bashrc

# Reload shell
source ~/.bashrc
```

**Windows (Git Bash):**
```bash
# Add to ~/.bashrc
echo "source $(pwd)/calma_aliases.sh" >> ~/.bashrc

# Reload
source ~/.bashrc
```

This gives you convenient commands:
- `calma` - Run main system
- `calma-web` - Open web interface
- `calma-logs` - View recent logs
- `calma-train` - Retrain ML models
- `calma-status` - Check system status

---

### Running CALMA

#### Method 1: Command Line

**With aliases (if configured):**
```bash
calma
```

**Without aliases:**
```bash
# Linux/macOS
./calma.sh

# Windows (Git Bash or WSL)
bash calma.sh
```

**What happens when you run it:**
1. **Phase 1:** Downloads email attachments from Gmail
2. **Phase 2:** Analyzes files using ML models
3. **Phase 3:** Classifies as Clean/Suspicious/Infected
4. **Phase 4:** Applies Gmail labels automatically
5. **Phase 5:** Generates execution report

#### Method 2: Web Interface

**Start web server:**
```bash
# With alias
calma-web

# Without alias
python3 scripts/utils/app.py  # Linux/macOS
python scripts/utils/app.py   # Windows
```

**Access in browser:**
```
http://localhost:5000
```

**Web interface features:**
- Dashboard with statistics
- View classification results
- Configure system settings
- View logs in real-time

---

### Verifying It Works

#### Check System Status

```bash
# With alias
calma-status

# Without alias
./test_compatibility.sh  # Linux/macOS
bash test_compatibility.sh  # Windows
```

This checks:
- Python version and dependencies
- Virtual environment
- Configuration file validity
- Gmail connectivity
- Directory structure

#### View Logs

```bash
# Recent logs
calma-logs

# Or manually
tail -f logs/execucao_*.log

# On Windows
Get-Content logs\execucao_*.log -Tail 50
```

#### Check Gmail Labels

1. Open Gmail in browser
2. Look in left sidebar
3. You should see these labels:
   - 📧 **Clean** - Safe attachments
   - ⚠️ **Suspicious** - Potentially dangerous
   - 🚨 **Infected** - Confirmed malware

---

### Automated Execution

**Linux/macOS - Add to crontab:**
```bash
# Run every hour
crontab -e

# Add line:
0 * * * * cd /path/to/calma && ./calma.sh >> logs/cron.log 2>&1
```

**Windows - Task Scheduler:**
```powershell
# Run hourly
schtasks /create /tn "CALMA" /tr "bash C:\path\to\calma\calma.sh" /sc HOURLY
```

---

### Configuration

**Option 1: Interactive Setup (Recommended)**
```bash
python setup.py
```

**Option 2: Manual Configuration**
1. Copy `config/calma_config.example.json` to `config/calma_config.json`
2. Configure your Gmail credentials (use App Password with 2FA)
3. Optionally add VirusTotal API key

### Usage

```bash
# CLI
./calma.sh

# Web UI
python3 scripts/utils/app.py
# Open: http://localhost:5000
```

### Documentation

- [Machine Learning Guide](docs/ML_Calma.md)
- [Security Guide](docs/Security.md)
- [Sandbox Guide](docs/Sandox.md)

### Project Structure

```
calma/
├── config/                 # Configuration files
├── scripts/
│   ├── detection/          # Detection engine
│   ├── ml/                 # ML models
│   └── utils/              # Utilities and web UI
├── templates/              # Web UI templates
├── docs/                   # Documentation
└── calma.sh                # Main script
```

### Requirements

- Python 3.8+
- `jq` (JSON parser)
- Git Bash or WSL (Windows only)

### Troubleshooting

| Problem | Solution |
|---------|----------|
| `jq` not found | Install via package manager |
| Template not found | Run from repo root directory |
| Windows path issues | Use Git Bash or WSL |
| Permission denied | Run `chmod +x calma.sh` |
| Import errors | Activate venv: `source venv/bin/activate` |

### Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md)

### License

MIT License - see [LICENSE](LICENSE)

---
---
---

# 🇵🇹 Documentação em Português

**CALMA** monitoriza anexos de email e classifica-os por nivel de risco usando machine learning. Seguro, isolado e multiplataforma.

### Funcionalidades

- **Multiplataforma:** Linux, macOS, Windows (Git Bash/WSL)
- **Machine Learning:** Modelos de analise PE e PDF
- **Integracao Gmail:** etiquetagem automatica (Limpo/Suspeito/Infectado)
- **Integracao VirusTotal:** analise sandbox em cloud (opcional)
- **Interface web:** monitorizacao e configuracao

### Inicio Rapido

```bash
# Clonar repositorio
git clone <repo-url> calma
cd calma

# Linux/macOS
./install_universal.sh

# Windows
python install_universal.py

# Configuracao interactiva (recomendado)
python setup.py

# Executar
./calma.sh
```

---

## Como Começar

### Configuração Inicial

#### Passo 1: Instalar Dependências

**Windows:**
```bash
# Usar PowerShell ou Linha de Comandos
python install_universal.py
```

Ou simplesmente executar `install_universal.bat`

**Linux/macOS:**
```bash
# Tornar script executável
chmod +x install_universal.sh

# Executar instalação
./install_universal.sh
```

**O que isto faz:**
- ✓ Verifica se Python 3.8+ está instalado
- ✓ Instala dependências do sistema (jq, etc.)
- ✓ Cria ambiente virtual
- ✓ Instala pacotes Python
- ✓ Cria estrutura de diretórios
- ✓ Cria ficheiro de configuração padrão

#### Passo 2: Configurar Gmail

**Opção A: Configuração Interativa (Recomendado)**
```bash
python setup.py
```

O assistente guia através de:
1. Seleção de idioma (Português/Inglês)
2. Verificação de requisitos
3. Credenciais Gmail (email + password de aplicação)
4. Chave API VirusTotal (opcional)
5. Configuração de etiquetas Gmail
6. Malware Bazar test sender (opcional)

**Opção B: Configuração Manual**
```bash
# Copiar configuração exemplo
cp config/calma_config.example.json config/calma_config.json

# Editar com as credenciais
nano config/calma_config.json  # Linux/macOS
notepad config/calma_config.json  # Windows
```

**Configuração Gmail Necessária:**
1. Ativar 2FA na conta Gmail
2. Gerar App Password em: https://myaccount.google.com/apppasswords
3. Usar a app password (não a password normal) na configuração

#### Passo 3: Configurar Atalhos (Opcional)

**Linux/macOS:**
```bash
# Adicionar ao ~/.bashrc ou ~/.zshrc
echo "source $(pwd)/calma_aliases.sh" >> ~/.bashrc

# Recarregar shell
source ~/.bashrc
```

**Windows (Git Bash):**
```bash
# Adicionar ao ~/.bashrc
echo "source $(pwd)/calma_aliases.sh" >> ~/.bashrc

# Recarregar
source ~/.bashrc
```

Isto disponibiliza comandos convenientes:
- `calma` - Executar sistema principal
- `calma-web` - Abrir interface web
- `calma-logs` - Ver logs recentes
- `calma-train` - Retreinar modelos ML
- `calma-status` - Verificar estado do sistema

---

### Executar CALMA

#### Método 1: Linha de Comandos

**Com atalhos (se configurado):**
```bash
calma
```

**Sem atalhos:**
```bash
# Linux/macOS
./calma.sh

# Windows (Git Bash ou WSL)
bash calma.sh
```

**O que acontece ao executar:**
1. **Fase 1:** Descarrega anexos do Gmail
2. **Fase 2:** Analisa ficheiros com modelos ML
3. **Fase 3:** Classifica como Limpo/Suspeito/Infectado
4. **Fase 4:** Aplica etiquetas Gmail automaticamente
5. **Fase 5:** Gera relatório de execução

#### Método 2: Interface Web

**Iniciar servidor web:**
```bash
# Com atalho
calma-web

# Sem atalho
python3 scripts/utils/app.py  # Linux/macOS
python scripts/utils/app.py   # Windows
```

**Aceder no navegador:**
```
http://localhost:5000
```

**Funcionalidades da interface web:**
- Painel com estatísticas
- Ver resultados de classificação
- Configurar definições do sistema
- Ver logs em tempo real

---

### Verificar Funcionamento

#### Verificar Estado do Sistema

```bash
# Com atalho
calma-status

# Sem atalho
./test_compatibility.sh  # Linux/macOS
bash test_compatibility.sh  # Windows
```

Isto verifica:
- Versão Python e dependências
- Ambiente virtual
- Validade do ficheiro de configuração
- Conectividade Gmail
- Estrutura de diretórios

#### Ver Logs

```bash
# Logs recentes
calma-logs

# Ou manualmente
tail -f logs/execucao_*.log

# No Windows
Get-Content logs\execucao_*.log -Tail 50
```

#### Verificar Etiquetas Gmail

1. Abrir Gmail no navegador
2. Ver na barra lateral esquerda
3. Deve ver estas etiquetas:
   - 📧 **Clean** - Anexos seguros
   - ⚠️ **Suspicious** - Potencialmente perigosos
   - 🚨 **Infected** - Malware confirmado

---

### Execução Automatizada

**Linux/macOS - Adicionar ao crontab:**
```bash
# Executar a cada hora
crontab -e

# Adicionar linha:
0 * * * * cd /path/to/calma && ./calma.sh >> logs/cron.log 2>&1
```

**Windows - Agendador de Tarefas:**
```powershell
# Executar a cada hora
schtasks /create /tn "CALMA" /tr "bash C:\path\to\calma\calma.sh" /sc HOURLY
```

---

### Configuracao

**Opcao 1: Configuracao Interactiva (Recomendado)**
```bash
python setup.py
```

**Opcao 2: Configuracao Manual**
1. Copiar `config/calma_config.example.json` para `config/calma_config.json`
2. Configurar credenciais Gmail (usar App Password com 2FA)
3. Opcionalmente adicionar chave API VirusTotal

### Utilizacao

```bash
# Linha de comandos
./calma.sh

# Interface web
python3 scripts/utils/app.py
# Abrir: http://localhost:5000
```

### Documentacao

- [Guia de Machine Learning](docs/ML_Calma.md)
- [Guia de Seguranca](docs/Security.md)
- [Guia de Sandbox](docs/Sandox.md)

### Estrutura do Projeto

```
calma/
├── config/                 # Ficheiros de configuracao
├── scripts/
│   ├── detection/          # Motor de deteccao
│   ├── ml/                 # Modelos ML
│   └── utils/              # Utilitarios e interface web
├── templates/              # Templates da interface web
├── docs/                   # Documentacao
└── calma.sh                # Script principal
```

### Requisitos

- Python 3.8+
- `jq` (parser JSON)
- Git Bash ou WSL (apenas Windows)

### Resolucao de Problemas

| Problema | Solucao |
|----------|---------|
| `jq` nao encontrado | Instalar via gestor de pacotes |
| Template nao encontrado | Executar a partir da raiz do repo |
| Problemas de path no Windows | Usar Git Bash ou WSL |
| Permissao negada | Executar `chmod +x calma.sh` |
| Erros de import | Ativar venv: `source venv/bin/activate` |

### Contribuir

Ver [CONTRIBUTING.md](CONTRIBUTING.md)

### Licenca

Licenca MIT - ver [LICENSE](LICENSE)


Licenca MIT - ver [LICENSE](LICENSE)

