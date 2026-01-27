# C.A.L.M.A - Classificador Automático de Links e Malware em Anexo
# C.A.L.M.A - Containerized Automated Lazy Mail Anti-nasties

O C.A.L.M.A é um sistema automatizado de análise de segurança de emails que integra com Cuckoo Sandbox para análise dinâmica de anexos. O sistema monitora emails recebidos, extrai anexos, envia para análise sandbox e classifica automaticamente os emails baseado nos resultados.

## Arquitetura

```
┌─────────────┐    ┌─────────────┐    ┌─────────────┐    ┌─────────────┐
│   Email     │──▶│  Fetchmail  │──▶│   CALMA     │──▶│   Cuckoo    │
│   Server    │    │             │    │   Script    │    │   Sandbox   │
└─────────────┘    └─────────────┘    └─────────────┘    └─────────────┘
                                                                │
┌─────────────┐    ┌─────────────┐    ┌─────────────┐           │
│   INFECTED  │◀──│ IMAPFilter  │◀──│   Results   │◀─────────┘
│   Folder    │    │             │    │   Analysis  │
└─────────────┘    └─────────────┘    └─────────────┘
```

## Instalação

### Pré-requisitos

- Ubuntu 20.04 LTS ou superior
- 8GB RAM mínimo (16GB recomendado)
- 50GB espaço em disco
- VirtualBox 6.1 ou superior
- Acesso root/sudo

### Passo 1: Clonar o Repositório

```bash
git clone https://github.com/0xadamastor/C.A.L.M.A.
cd C.A.L.M.A.
```

### Passo 2: Instalar Dependências

```bash
chmod +x install_dependencies.sh

sudo ./install_dependencies.sh
```

### Passo 3: Configurar VirtualBox

```bash
sudo usermod -a -G vboxusers $USER

sudo setcap cap_net_raw,cap_net_admin=eip /usr/sbin/tcpdump

sudo reboot
```

### Passo 4: Configurar Cuckoo Sandbox

```bash
cuckoo init

cuckoo machine --add win7ultimate /opt/win7ultimate/win7ultimate.vbox

cuckoo -d
```

### Passo 5: Verificar Instalação

```bash
curl http://localhost:8090

VBoxManage list vms
VBoxManage showvminfo win7ultimate
```

## Configuração

### 1. Configuração de Email

#### fetchmailrc
```bash
sudo nano /opt/calma/config/fetchmailrc
```

```config
poll imap.gmail.com
protocol IMAP
user "email@gmail.com"
password "xxxx xxxx xxxx xxxx"
ssl
sslproto TLS1.2
sslcertck
keep
mda "/usr/bin/maildrop -d %T"
limit 10485760
fetchall
no keep
```

**Nota:** Para Gmail, use "Senha de App" não a senha normal.

#### imapfilter_config.lua
```bash
sudo nano /opt/calma/config/imapfilter_config.lua
```

```lua
options.timeout = 120
options.subscribe = true

SERVER = 'imap.gmail.com'
USERNAME = 'emial@gmail.com'
PASSWORD = 'xxxx xxxx xxxx xxxx'

account = IMAP {
    server = SERVER,
    username = USERNAME,
    password = PASSWORD,
    ssl = 'auto',
}

inbox = account.INBOX

account:create_mailbox('Infected')
account:create_mailbox('Clean')

infected_folder = account['Infected']
clean_folder    = account['Clean']

print('CALMA: IMAPFilter conectado ao Gmail com sucesso')
```

### 2. Configurar Permissões

```bash
sudo chown -R $USER:$USER /opt/calma
sudo chmod 600 /opt/calma/config/fetchmailrc
sudo chmod 755 /opt/calma/scripts/*.sh

sudo mkdir -p /var/log/cuckoo
sudo chown $USER:$USER /var/log/cuckoo
```

### 3. Configurar Cuckoo

```bash
nano ~/.cuckoo/conf/cuckoo.conf
```

```ini
[cuckoo]
machinery = virtualbox
analysis_timeout = 300
memory_dump = no
delete_original = no
```

```bash
nano ~/.cuckoo/conf/virtualbox.conf
```

```ini
[virtualbox]
machines = win7ultimate
[win7ultimate]
label = win7ultimate
platform = windows
ip = 192.168.56.101
snapshot = clean
```

### 4. Configurar CRON Job

```bash
chmod +x /opt/calma/scripts/calma_cron.sh
/opt/calma/scripts/calma_cron.sh

crontab -l
```

## Uso

### Iniciar Manualmente

```bash
cuckoo -d

/opt/calma/scripts/calma_cuckoo.sh

tail -f /opt/calma/logs/system/calma_system.log
tail -f /var/log/cuckoo/cuckoo.log
```

### Verificar Status

```bash
curl -s http://localhost:8090/tasks/list | jq .

ps aux | grep cuckoo
ps aux | grep virtualbox

ls -la /opt/calma/incoming/
cat /opt/calma/logs/forensic/calma_forensic.csv
```

### Testar o Sistema

#### Teste 1: Enviar Email de Teste
```bash
echo "Teste CALMA" | mail -s "Teste Limpo" -A /etc/hosts seu.email@gmail.com

echo 'X5O!P%@AP[4\PZX54(P^)7CC)7}$EICAR-STANDARD-ANTIVIRUS-TEST-FILE!$H+H*' > eicar.txt
echo "Teste CALMA" | mail -s "Teste EICAR" -A eicar.txt seu.email@gmail.com
```

#### Teste 2: Verificar Processamento
```bash
/opt/calma/scripts/calma_cuckoo.sh

ls -la /opt/calma/sandbox/malicious/
ls -la /opt/calma/sandbox/clean/
```

## Estrutura de Diretórios

```
/opt/calma/
├── config/                          # Configurações
│   ├── fetchmailrc                 # Config email (entrada)
│   └── imapfilter_config.lua       # Config email (saída)
├── scripts/                        # Scripts do sistema
│   ├── calma_cuckoo.sh            # Script principal
│   ├── install_dependencies_cuckoo.sh
│   └── calma_cron.sh
├── incoming/                       # Emails baixados
├── attachments/                    # Anexos extraídos
├── sandbox/                        # Integração Cuckoo
│   ├── pending/                   # Aguardando análise
│   ├── processing/                # Em análise
│   ├── completed/                 # Análise concluída
│   ├── malicious/                 # Arquivos maliciosos
│   └── clean/                     # Arquivos limpos
├── reports/                       # Relatórios Cuckoo
├── quarantine/                    # Arquivos em quarentena
└── logs/                          # Logs do sistema
    ├── forensic/                  # Logs forenses (CSV)
    ├── analysis/                  # Logs de análise
    └── system/                    # Logs do sistema
```

## Segurança

### Recomendações
1. **Isolamento**: Execute em rede isolada
2. **Firewall**: Restrinja acesso à API Cuckoo (porta 8090)
3. **Logs**: Monitore logs regularmente
4. **Updates**: Mantenha Cuckoo e dependências atualizadas
5. **Quarentena**: Revise periodicamente arquivos em quarentena

### Configurações de Segurança
```bash
# Restringir acesso à API Cuckoo
sudo ufw deny 8090
# OU permitir apenas localhost
sudo ufw allow from 127.0.0.1 to any port 8090

# Configurar logrotate
sudo nano /etc/logrotate.d/calma
```

```config
/opt/calma/logs/system/*.log {
    daily
    rotate 30
    compress
    delaycompress
    missingok
    notifempty
    create 644 root root
}
```

## Monitoramento

### Scripts Úteis

#### monitor_calma.sh
```bash
#!/bin/bash
echo "=== STATUS CALMA ==="
echo "Cuckoo API: $(curl -s http://localhost:8090 -o /dev/null -w '%{http_code}')"
echo "Emails aguardando: $(ls -1 /opt/calma/incoming/*.email 2>/dev/null | wc -l)"
echo "Arquivos em análise: $(ls -1 /opt/calma/sandbox/processing/ 2>/dev/null | wc -l)"
echo "Total maliciosos: $(ls -1 /opt/calma/sandbox/malicious/ 2>/dev/null | wc -l)"
echo "Último processamento: $(tail -1 /opt/calma/logs/system/calma_system.log 2>/dev/null)"
```

#### backup_calma.sh
```bash
#!/bin/bash
BACKUP_DIR="/backup/calma_$(date +%Y%m%d)"
mkdir -p $BACKUP_DIR
cp -r /opt/calma/logs $BACKUP_DIR/
cp -r /opt/calma/reports $BACKUP_DIR/
mysqldump -u cuckoo -p cuckoo > $BACKUP_DIR/cuckoo_db.sql
tar -czf $BACKUP_DIR.tar.gz $BACKUP_DIR
```

## Licença

Por favor não roubes!

## Agradecimentos

- [Cuckoo Sandbox](https://cuckoosandbox.org/)
- [VirusTotal](https://www.virustotal.com/)
- [TheZoo](https://github.com/ytisf/theZoo)

