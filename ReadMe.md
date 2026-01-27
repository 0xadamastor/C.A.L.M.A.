# C.A.L.M.A - Classificador Automático de Links e Malware em Anexo
# C.A.L.M.A - Containerized Automated Lazy Mail Anti-nasties

Um sistema automatizado para análise de segurança de emails que verifica anexos em tempo real e os classifica como seguros ou maliciosos.

## Requisitos do Sistema

- Ubuntu/Debian ou distribuição Linux similar
- Acesso root/sudo
- Conexão com internet
- Conta de email com acesso IMAP habilitado

## Instalação

### 1. Clonar ou baixar os arquivos

```bash
# Make directory
sudo mkdir -p /opt/calma
cd /opt/calma

sudo wget -O install_dependencies.sh https://raw.githubusercontent.com/0xadamastor/C.A.L.M.A./edit/xanax/install_dependencies.sh
sudo wget -O calma.sh https://raw.githubusercontent.com/0xadamastor/C.A.L.M.A./edit/xanax/scripts/calma.sh
sudo wget -O imapfilter_config.lua https://raw.githubusercontent.com/0xadamastor/C.A.L.M.A./edit/xanax/config/imapfilter_config.lua

sudo chmod +x install_dependencies.sh calma.sh
```

### 2. Executar instalação de dependências

```bash
sudo ./install_dependencies.sh
```

Este script irá:
- Atualizar o sistema
- Instalar todas as dependências necessárias
- Configurar diretórios do CALMA
- Instalar ClamAV (antivírus para análise)

### 3. Configurar estrutura de diretórios

```bash
sudo mkdir -p /opt/calma/{config,scripts,incoming,attachments,reports,quarantine,logs/{forensic,analysis,system}}
sudo mkdir -p /opt/calma/attachments/clean

sudo mv calma.sh /opt/calma/scripts/
sudo mv imapfilter_config.lua /opt/calma/config/

sudo chmod 755 /opt/calma/scripts/calma.sh
sudo chown -R $USER:$USER /opt/calma  # Ou o utilizador que executará o script
```

## Configuração

### 1. Configurar Fetchmail (para download de emails)

Crie o arquivo `/opt/calma/config/fetchmailrc`:

```bash
nano /opt/calma/config/fetchmailrc
```

Adicione (substitua com suas credenciais):

```
poll imap.gmail.com
protocol IMAP
user "email@gmail.com"
password "senha_da_app"
ssl
fetchall
keep
mda "/usr/bin/munpack -f -q -C /opt/calma/incoming"
```

**Importante**: Para Gmail, você precisa:
1. Ativar IMAP em: Configurações → Encaminhamento e POP/IMAP
2. Criar uma "Senha de App": Google Account → Segurança → Senhas de App

### 2. Configurar IMAPFilter (para mover emails)

Edite o arquivo `/opt/calma/config/imapfilter_config.lua`:

```bash
nano /opt/calma/config/imapfilter_config.lua
```

Atualize com suas credenciais:

```lua
SERVER = 'imap.gmail.com'
USERNAME = 'email@gmail.com'
PASSWORD = 'senha_de_app'
```

### 3. Testar configurações

```bash
fetchmail --fetchmailrc /opt/calma/config/fetchmailrc -v

imapfilter -c /opt/calma/config/imapfilter_config.lua

/opt/calma/scripts/calma.sh
```

## ⏰ Configurar Cron Job (Execução Automática)

### Opção 1: Para o utilizador atual

```bash
crontab -e
```

Adicione a linha:

```bash
*/10 * * * * /opt/calma/scripts/calma.sh >> /opt/calma/logs/cron.log 2>&1

0 * * * * /opt/calma/scripts/calma.sh >> /opt/calma/logs/cron.log 2>&1
```

### Opção 2: Para todos os utilizadores (sistema)

```bash
sudo nano /etc/cron.d/calma
```

Adicione:

```bash
*/5 * * * * root /opt/calma/scripts/calma.sh >> /opt/calma/logs/cron.log 2>&1
```

## Testar o Sistema
Teste 1: Enviar arquivo "limpo"

```bash
echo "Este é um documento seguro" > /tmp/teste_limpo.txt

echo "Teste CALMA - Arquivo limpo" | mail -s "Teste Limpo" \
    -a /tmp/teste_limpo.txt seu_email_analise@gmail.com
```
Teste 2: Enviar arquivo "suspeito"

```bash

# Criar arquivo com strings suspeitas
echo -e "Conteúdo normal\nexecute exploit\nmalware signature\n" > /tmp/teste_suspeito.exe

echo "Teste CALMA - Arquivo suspeito" | mail -s "Teste Suspeito" \
    -a /tmp/teste_suspeito.exe seu_email_analise@gmail.com
```

### 2. Verificar logs

```bash
tail -f /opt/calma/logs/system/calma_system.log

# Logs forenses
cat /opt/calma/logs/forensic/calma_forensic.csv

# Log do cron
cat /opt/calma/logs/cron.log
```

### 3. Verificar resultados

```bash
ls -la /opt/calma/quarantine/

# Verificar arquivos limpos
ls -la /opt/calma/attachments/clean/

# Verificar relatórios
ls -la /opt/calma/reports/
```

## Estrutura de Arquivos

```
/opt/calma/
├── config/
│   ├── fetchmailrc              # Configuração do Fetchmail
│   └── imapfilter_config.lua    # Configuração do IMAPFilter
├── scripts/
│   └── calma.sh                 # Script principal
├── incoming/                    # Emails baixados (temporário)
├── attachments/                 # Anexos extraídos
│   └── clean/                  # Arquivos classificados como seguros
├── quarantine/                  # Arquivos maliciosos
├── reports/                     # Relatórios de análise (futuro)
└── logs/
    ├── system/                  # Logs do sistema (calma_system.log)
    ├── forensic/                # Logs forenses (calma_forensic.csv)
    └── analysis/                # Logs detalhados de análise
```

## Segurança

1. **Credenciais**: Mantenha os arquivos de configuração com permissões restritas:
   ```bash
   chmod 600 /opt/calma/config/fetchmailrc
   chmod 600 /opt/calma/config/imapfilter_config.lua
   ```

## Licença

Por favor não roubes!

## Contribuição

Para reportar bugs ou sugerir melhorias:
1. Verifique os logs em `/opt/calma/logs/`
2. Documente os passos para reproduzir o problema
3. Inclua trechos relevantes dos logs





