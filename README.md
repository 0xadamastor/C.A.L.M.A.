# CALMA - Containerized Automated Lazy Mail Anti-nasties

**CALMA** is your paranoid email security guard. It automatically extracts, analyzes, and categorizes email attachments with the enthusiasm of a postal worker who's *really* concerned about what's in those packages. No more wondering if that "invoice.exe" from your "boss" is actually what it claims to be.

## Quick Start - Instalação em 30 Segundos

The beautiful part about CALMA's installer is that it works everywhere. No more "it doesn't work on my machine" excuses.

### No Linux ou macOS (Pick One):
```bash
cd calma
./install.sh
```

### No Windows:
```bash
cd calma
install.bat
```

Or if you want to be fancy (works on any OS):
```bash
python3 install.py
```

**O instalador vai fazer o trabalho chato por você:**
- Verifica se tens Python 3.8+ instalado (senão, reclama muito)
- Cria um ambiente virtual chamado `venv` (para não estragar o teu sistema)
- Instala todas as dependências do requirements.txt
- Cria a estrutura de pastas necessária
- Verifica que tudo funcionou (spoiler: funciona)
- Mostra instruções de como executar CALMA

Basicamente, é como um eletricista que vem à tua casa, faz tudo, e depois te deixa um manual com a factura. Mas grátis.

---

## What Can This Beast Do?

[AUTO-PILOT MODE]
- **Automatic Email Hunting**: Crawls through your inbox like it owns the place, looking for attachments
- **File Extraction Wizardry**: Pulls attachments out of emails and lines them up for inspection
- **The Verdict Chamber**: Judges each file and assigns it one of three destinies:
  - **CLEAN** ──→ Your boring, trustworthy files (score < 30)
  - **SUSPICIOUS** ──→ That sketchy file your friend sent (score 30-69)  
  - **INFECTED** ──→ Absolutely not touching this (score ≥ 70)
- **Gmail Label Magic**: Automatically organizes emails into labeled folders (your inbox won't look like a landfill)
- **Report Generation**: Creates pretty reports that make you look tech-savvy at meetings
- **Cryptographic Hashing**: Calculates SHA256 hashes so you can prove files are exactly as malicious as you thought
- **Obsessive Logging**: Records everything, because paranoia is good practice in cybersecurity
- **Self-Cleaning**: Automatically deletes old logs before your disk explodes

## What You'll Need (The Boring Part)

- **OS**: Windows, macOS, Linux - qualquer um funciona (finalmente, igualdade!)
- **Python**: 3.8 ou mais recente (o instalador verifica por ti)
- **Interpretador de Bash** (para os scripts manuais, opcional se usares a web UI)
- **Internet**: Para falar com o Gmail ou analisar ficheiros online

## Let's Get This Thing Running

### Step 1: Executar o Instalador (Mesmo isto é Fácil)

```bash
cd ~
git clone <repository-url> calma
cd calma
python3 install.py
```

E pronto. O instalador faz tudo. Podes ir fazer café.

### Step 2: Ativar o Ambiente Virtual

```bash
# Linux ou macOS
source venv/bin/activate

# Windows
venv\Scripts\activate
```

### Step 3: Executar CALMA

```bash
python3 app.py
```

Acede a http://localhost:5000 e começa a usar. Feliz?

## Configuração Avançada (Opcional)

Se quiseres usar as funcionalidades de email automático:

### Create the Gmail Labels (The Official Part)

1. Visit [Gmail Settings](https://mail.google.com/mail/u/0/#settings)
2. Smash that "Labels" tab
3. Create these three labels:
   - `Infected` ──→ For files that smell like trouble
   - `Suspicious` ──→ For files that are kinda sus
   - `Clean` ──→ For the boring, trustworthy stuff

Can't be bothered? Run this:

```bash
chmod +x labels.sh
./labels.sh
```

(It'll do the boring work for you)

### Step 3: The Gmail App Password Dance

Google decided that trusting your regular password to random scripts is not cool (they're right, honestly). So you need an **App Password**:

1. Head to [myaccount.google.com/security](https://myaccount.google.com/security)
2. Make sure **2-Step Verification** is already on (it should be, come on)
3. Find **App passwords** (under "Your Google Account")
4. Pick "Mail" and pretend you're on a "Windows Computer" (Google doesn't really care what you pick)
5. Google hands you a 16-character password that looks like alphabet soup
6. Copy this. You'll need it next.

### Step 4: Configure CALMA (The Actual Setup)

Edit [calma.sh](calma.sh) and change these at the top:

```bash
EMAIL_USER="your-email@gmail.com"          # Put your Gmail here
EMAIL_PASS="your-16-char-app-password"     # Paste that alphabet soup
```

Want to be fancy? Adjust these too:

```bash
MAX_FILE_SIZE="10485760"          # Don't bother analyzing files bigger than 10MB
SCAN_TIMEOUT="300"                # Give up after 5 minutes of analysis
KEEP_LOGS_DAYS="7"                # Delete logs older than a week
HASH_ALGORITHM="sha256"           # MD5 is dead, use this instead
ENABLE_METADATA="true"            # Save metadata about every file
```

### Step 5: Make Everything Executable

```bash
chmod +x calma.sh labels.sh config.sh
```

(Otherwise bash will complain about permissions like a grumpy old man)

## Time to Actually Run This Thing

### Com o Ambiente Virtual Ativado

Depois que o instalador termina, tens um ambiente virtual isolado chamado `venv`. Para ativar:

**No Linux ou macOS:**
```bash
source venv/bin/activate
python3 app.py
```

**No Windows:**
```bash
venv\Scripts\activate
python app.py
```

E pronto - CALMA está rodando em http://localhost:5000

### A Interface Web

Sim, CALMA tem interface web. Não é preciso correr scripts de terminal feito um hacker dos anos 90 (embora seja cool). A web UI é mais bonita, mais intuitiva, e não faz parecer que estás a desatualizar código espaço:

- Upload de ficheiros para análise
- Histórico de análises
- Estatísticas e relatórios
- Logs em tempo real
- Configuração através da UI

### Scripts Manuais (Para os Nostálgicos)

Se preferires a velha escola, ainda tens os scripts bash:

```bash
./calma.sh
```

CALMA vai então:

1. Verificar se as labels do Gmail existem (paranoia em nível saudável)
2. Criar a estrutura de pastas se não existir
3. Procurar emails não lidos com anexos
4. Extrair e analisar cada ficheiro com intensidade
5. Atribuir a cada ficheiro o seu destino (Limpo, Suspeito, ou Infetado)
6. Mover os emails para as labels certas do Gmail
7. Guardar tudo nos sítios corretos
8. Gerar um bonito relatório
9. Apagar logs antigos antes que o disco expluda

### Automação com Cron (O Jeito Preguiçoso)

Quer deixar CALMA a funcionar sozinho tipo um daemon paranóico? Usa cron:

#### Cada Hora (O Vigia Constante)

```bash
crontab -e
```

Adiciona:
```cron
0 * * * * /home/username/calma/venv/bin/python /home/username/calma/app.py >> /home/username/calma/logs/cron.log 2>&1
```

#### Cada 30 Minutos (A Opção Paranoica)

```cron
*/30 * * * * /home/username/calma/venv/bin/python /home/username/calma/app.py >> /home/username/calma/logs/cron.log 2>&1
```

#### Cada 10 Minutos (Isto é Exagero Mas Tudo Bem)

```cron
*/10 * * * * /home/username/calma/venv/bin/python /home/username/calma/app.py >> /home/username/calma/logs/cron.log 2>&1
```

Ou simplesmente executa o script helper:

```bash
chmod +x configurar_cron.sh
./configurar_cron.sh
```

## Estrutura do Projeto

```
calma/
├── install.py                    # Instalador cross-platform (executa em qualquer SO)
├── install.sh                    # Script wrapper para Linux/macOS
├── install.bat                   # Script wrapper para Windows
├── app.py                        # API Python e interface web
├── requirements.txt              # Dependências Python (atualizado para compatibilidade)
├── venv/                         # Ambiente virtual (criado pelo instalador)
├── calma.sh                      # Script de análise de email (opcional)
├── labels.sh                     # Cria labels no Gmail (opcional)
├── config.sh                     # Helper de configuração (opcional)
├── README.md                     # Este documento
├── logs/                         # Histórico de execuções
├── dados/                        # Ficheiros processados
│   ├── anexos_processados/
│   │   ├── a_analisar/
│   │   ├── limpos/
│   │   ├── suspeitos/
│   │   └── infetados/
│   └── quarentena/
└── templates/                    # Templates HTML para a web UI
```

## O Sistema de Julgamento (Como CALMA Decide o Destino do Teu Ficheiro)

CALMA é como um porteiro de discoteca, mas da tua máquina. Julga ficheiros baseado no tipo e comportamento suspeito.

```
SCORE RANGE    │ VEREDICTO   │ O QUE ACONTECE
───────────────┼─────────────┼──────────────────────────
0 - 29         │ LIMPO       │ Tudo bem com esse ficheiro
30 - 69        │ SUSPEITO    │ Anda perto, mas duvido
70 - 100       │ INFETADO    │ Queima com fogo divino
```

### Regras de Pontuação (Porque é Que os Ficheiros São Julgados Assim)

| Tipo de Ficheiro | Score | Porque? |
|---|---|---|
| .exe, .bat, .dll, .scr | 80-100 | Executáveis Windows são suspeitos por defeito |
| .js, .jar, .vbs, .hta | 60-90 | Scripts podem mexer no teu sistema |
| .zip, .rar, .7z | 40-70 | Arquivos são como caixas mistério |
| .pdf, .doc, .xlsx | 20-60 | Ficheiros Office podem ter macros (enganadores) |
| .mp3, .mp4, .jpg, .txt | 0-20 | Ficheiros média geralmente não querem te matar |

### Red Flags no Filename (As Pistas Óbvias)

Alguns ficheiros praticamente gritam o que são:

- **"virus", "malware", "trojan", "ransomware"** → Score: 85 (não, obrigado)
- **"suspicious", "danger"** → Score: 50 (tá muito suspeito)
- **"safe", "clean", "example"** → Score: 10 (provavelmente ok)

## Verificar os Relatórios (aka "Prova que Funciona")

Após CALMA executar, deixa pistas em toda a parte:

```bash
# O relatório mais recente
cat logs/relatorio_*.txt | tail -1

# Ver o log de execução (para debugging)
tail -f logs/execucao_*.log

# Olhar para metadados (se tens disposição)
cat dados/anexos_processados/infetados/file.ext.meta
```

Um ficheiro de metadados típico parece assim:
```
=== FILE METADATA ===
Filename: definitely-not-virus.exe
Hash (sha256): a1b2c3d4e5f6...
Size: 2048576 bytes
From: your-totally-legit-friend@email.com
Extracted: 2026-01-28 15:30:45
Classification: INFECTED
Score: 87/100
```

## Coisas Que Correm Mal (Troubleshooting)

### "ERRO: Authentication failed" / "Login credentials invalid"

Your Gmail is being stubborn. Try:

1. **Are you using an App Password?** (not your regular Gmail password - that won't work)
2. **Is 2-Step Verification enabled?** (It should be on your Google Account)
3. **Did you copy the password correctly?** (Those 16 characters are finicky)

### "Labels don't exist in Gmail"

CALMA is looking for labels that aren't there. Fix it:

```bash
./labels.sh  # Creates them automatically
```

Then run CALMA again.

### "No new emails found" / Nothing happens

This isn't an error - it just means your inbox has no unread emails with attachments. CALMA will get to work as soon as you send yourself a test email with an attachment.

### "Python3 not found" / "command not found: python3"

Your system is missing Python. Install it:

```bash
sudo apt update
sudo apt install python3 python3-pip
```

### Everything's slow / Timeouts keep happening

CALMA is being patient, but your email has a lot of stuff. Try increasing the timeout:

```bash
SCAN_TIMEOUT="600"  # Give it 10 minutes instead of 5
```

### "Permission denied" when running the script

You forgot to make it executable:

```bash
chmod +x calma.sh labels.sh configurar_cron.sh
```

## Advanced Tweaking (For the Brave)

### Different Hash Algorithm

MD5 is dead (cryptographically), but if you're nostalgic:

```bash
HASH_ALGORITHM="md5"    # Vintage vibes
HASH_ALGORITHM="sha1"   # Less dead than MD5
HASH_ALGORITHM="sha256" # The responsible choice
```

### Turn Off Metadata

If you don't care about file history and metadata:

```bash
ENABLE_METADATA="false"
```

(But why would you do this?)

## Log Files

CALMA generates comprehensive logs:

- **execucao_*.log** - Session execution logs with timestamps
- **relatorio_*.txt** - Human-readable execution reports
- **email_map_*.txt** - Mapping between emails and extracted files
- **.meta files** - File metadata including hash, size, origin

Example metadata:
```
=== METADADOS DO ANEXO ===
Nome do ficheiro: document.pdf
Hash (sha256): a1b2c3d4e5f6...
Tamanho: 2048576 bytes
Email de origem: sender@example.com
Data de extração: 2026-01-28 15:30:45
```

## The Boring But Important Part (Security Best Practices)

1. **Nunca, MESMO NUNCA, faças commit das tuas credenciais do Gmail**
   (Credenciais num repo público é crime de segurança)

2. **Usa App Passwords, não a tua password principal do Gmail**
   (App Passwords são como uma chave que funciona só numa porta)

3. **Ativa 2-Step Verification na tua conta Google**
   (Não é opcional, é apenas inteligente)

4. **Verifica os logs regularmente**
   (Atividade estranha? Os logs dizem-te tudo)

5. **Guarda backups dos emails importantes**
   (Antes de CALMA apagar algo, faz backup)

6. **Revê a pasta "Suspeito" realmente**
   (Não apagues coisas sem olhar primeiro)

7. **Atualiza o teu sistema regularmente**
   (Novos patches de segurança saem por uma razão)

8. **Não confies 100% nisto**
   (CALMA é um ajudante, não uma garantia. Malware real é sofisticado)

## O Que Isto É (E O Que Não É)

**CALMA É:**
- Uma ferramenta de automação para gestão de anexos
- Um classificador heurístico (suposições educadas)
- Um auditor que guarda logs
- Um organizador de Gmail turboalimentado

**CALMA NÃO É:**
- Um antivírus profissional (não executa ficheiros realmente)
- Uma garantia contra malware sofisticado
- Um substituto para treino real de segurança
- Uma razão para parares de suspeitar de anexos de email

## Problemas? Sugestões?

1. Lê a secção de Troubleshooting acima primeiro
2. Verifica os logs em `logs/` - contam uma história
3. Confirma que todos os passos de configuração foram completados
4. Certifica-te que o IMAP do Gmail está realmente ativado

---

**Version**: 1.0  
**Status**: "Funciona na minha máquina" (em Janeiro de 2026)  
**Warranty**: Absolutamente nenhuma. Usa por tua conta e risco.  
**Atitude**: Construído com paranoia e desconfiança saudável de anexos de email
