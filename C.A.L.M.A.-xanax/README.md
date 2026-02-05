# CALMA - Containerized Automated Lazy Mail Anti-nasties

```
██████╗ █████╗ ██╗     ███╗   ███╗ █████╗
██╔════╝██╔══██╗██║     ████╗ ████║██╔══██╗
██║     ███████║██║     ██╔████╔██║███████║
██║     ██╔══██║██║     ██║╚██╔╝██║██╔══██║
╚██████╗██║  ██║███████╗██║ ╚═╝ ██║██║  ██║
 ╚═════╝╚═╝  ╚═╝╚══════╝╚═╝     ╚═╝╚═╝  ╚═╝
```

[English](#english) | [Portugues](#portugues)

---

## English

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

---

## Portugues

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

---

## Project Structure / Estrutura do Projeto

```
calma/
├── config/                 # Configuration / Configuracao
├── scripts/
│   ├── detection/          # Detection engine / Motor de deteccao
│   ├── ml/                 # ML models / Modelos ML
│   └── utils/              # Utilities and web UI
├── templates/              # Web UI templates
├── docs/                   # Documentation / Documentacao
└── calma.sh                # Main script / Script principal
```

---

## Requirements / Requisitos

- Python 3.8+
- `jq` (JSON parser)
- Git Bash or WSL (Windows only)

---

## Troubleshooting / Resolucao de Problemas

| Problem / Problema | Solution / Solucao |
|-------------------|-------------------|
| `jq` not found | Install via package manager |
| Template not found | Run from repo root directory |
| Windows path issues | Use Git Bash or WSL |

---

## Contributing / Contribuir

See [CONTRIBUTING.md](CONTRIBUTING.md)

## License / Licenca

MIT License - see [LICENSE](LICENSE)
