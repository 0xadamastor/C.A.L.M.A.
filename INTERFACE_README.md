# CALMA - Sistema Automático de Análise de Anexos
## Interface Web de Controlo e Configuração

---

## 📋 Índice

1. [Visão Geral](#visão-geral)
2. [Requisitos](#requisitos)
3. [Instalação Rápida](#instalação-rápida)
4. [Como Usar](#como-usar)
5. [Funcionalidades](#funcionalidades)
6. [Resolução de Problemas](#resolução-de-problemas)

---

## 🎯 Visão Geral

A interface web do CALMA oferece uma forma intuitiva e visualmente apelativa para:

- ⚙️ **Configurar** o sistema completamente (email, labels, cron, parâmetros avançados)
- 📊 **Monitorizar** o estado do serviço e estatísticas em tempo real
- 📋 **Visualizar** logs e eventos do sistema
- 🚀 **Executar** análises manualmente
- 🔗 **Testar** conexões com o Gmail

---

## ✅ Requisitos

- **Python 3.7+**
- **Acesso à terminal/shell**
- **Navegador web moderno** (Chrome, Firefox, Safari, Edge)
- **Sistema operativo**: Linux, macOS ou Windows (WSL2)

### Dependências Python

As dependências são instaladas automaticamente na primeira execução:

- `Flask` - Framework web
- `imaplib` - Suporte para IMAP (incluído no Python)

---

## 🚀 Instalação Rápida

### Opção 1: Script Automático (Recomendado)

```bash
cd /home/samu/calma
chmod +x start_interface.sh
./start_interface.sh
```

### Opção 2: Script Simplificado

```bash
cd /home/samu/calma
chmod +x run_interface.sh
./run_interface.sh
```

### Opção 3: Manualmente

```bash
cd /home/samu/calma

# Criar ambiente virtual
python3 -m venv venv
source venv/bin/activate

# Instalar dependências
pip install flask

# Iniciar
python3 app.py
```

---

## 💻 Como Usar

### 1. Acessar a Interface

Após iniciar o script, abra o navegador e aceda a:

```
http://localhost:5000
```

### 2. Configurar o Sistema

#### Email e Credenciais
1. Vá ao separador **⚙️ Configuração**
2. Preencha os dados:
   - **Email**: seu.email@gmail.com
   - **App Password**: Código de 16 caracteres do Gmail (com espaços)
   - **Servidor IMAP**: imap.gmail.com (padrão)
3. Clique em **🔗 Testar Conexão**
4. Quando OK, clique em **💾 Guardar Configuração**

#### Labels do Gmail
No mesmo separador, configure os nomes das labels:
- **Label para Ficheiros Limpos**: Clean (predefinido)
- **Label para Ficheiros Infetados**: Infected (predefinido)
- **Label para Ficheiros Suspeitos**: Suspicious (predefinido)

#### Cron (Execução Automática)
1. Ative o toggle **Ativar Execução Automática**
2. Defina o intervalo em minutos (ex: 5 minutos)
3. Clique em **💾 Guardar Configuração**

#### Configurações Avançadas
Customize conforme necessário:
- **Tamanho máximo de ficheiro** (em bytes)
- **Timeout de análise** (em segundos)
- **Dias de retenção de logs**
- **Algoritmo de hash** (MD5, SHA1, SHA256)
- **Gerar metadados** (ativar/desativar)

### 3. Monitorizar o Sistema

#### Dashboard
- Visualize o **Estado do Serviço** (Cron, Configuração, Labels)
- Veja as **Estatísticas de Classificação**:
  - Ficheiros Limpos (seguros)
  - Ficheiros Infetados (perigosos)
  - Ficheiros Suspeitos (analisar)
  - Ficheiros Pendentes (a processar)

#### Monitorização em Tempo Real
1. Vá ao separador **📈 Monitorização**
2. Clique em **▶️ Iniciar** para monitorizar em tempo real
3. As estatísticas atualizam a cada 5 segundos
4. Clique em **⏸ Parar** para interromper

#### Logs
1. Vá ao separador **📋 Logs**
2. Clique em **🔄 Atualizar Logs** para ver os mais recentes
3. Visualize eventos com cores:
   - 🟢 Verde: Sucesso
   - 🔵 Azul: Informação
   - 🟡 Amarelo: Aviso
   - 🔴 Vermelho: Erro

### 4. Executar Análises Manualmente

**No Dashboard**, clique em **▶️ Executar Agora** para:
- Extrair anexos não lidos do Gmail
- Processar ficheiros pendentes
- Classificar automaticamente
- Mover para labels correspondentes

---

## 🎨 Funcionalidades

### 📊 Dashboard
- Estado em tempo real do serviço
- Estatísticas de ficheiros por classificação
- Indicadores visuais (badges com cores)
- Última execução e próxima execução (se cron ativo)

### ⚙️ Configuração
**Seção de Email:**
- Autenticação com Gmail
- Teste de conexão IMAP
- Validação de credenciais

**Seção de Labels:**
- Configurar nomes das labels
- Sincronizar com Gmail
- Validar existência

**Seção de Cron:**
- Ativar/desativar execução automática
- Definir intervalo de execução
- Verificar status atual

**Seção Avançada:**
- Parâmetros de segurança
- Limites de tamanho
- Algoritmos de hash
- Retenção de logs

### 📈 Monitorização
- Atualização em tempo real
- Gráfico de estatísticas
- Histórico de eventos
- Limpeza de logs antigos

### 📋 Logs
- Visualização com syntax highlighting
- Pesquisa e filtragem
- Download de logs
- Limpeza automática

---

## 🔧 Variáveis de Ambiente

Pode definir a porta manualmente:

```bash
# Executar na porta 8080
PORT=8080 ./start_interface.sh

# Ou
export PORT=8080
./start_interface.sh
```

---

## 📁 Estrutura de Ficheiros

```
calma/
├── app.py                      # Aplicação Flask (backend)
├── start_interface.sh          # Script de inicialização completo
├── run_interface.sh            # Script simplificado
├── calma.sh                    # Script principal do sistema
├── config.sh                   # Configurações globais
├── configurar_cron.sh          # Script de cron
├── templates/
│   └── index.html              # Interface web
├── calma_config.json           # Configuração (criado automaticamente)
├── logs/
│   ├── execucao_*.log          # Logs de execução
│   ├── cron.log                # Log do cron
│   └── web_*.log               # Log da interface web
├── dados/
│   ├── anexos_processados/
│   │   ├── limpos/             # Ficheiros seguros
│   │   ├── infetados/          # Ficheiros perigosos
│   │   ├── suspeitos/          # Ficheiros suspeitos
│   │   └── a_analisar/         # Ficheiros pendentes
│   └── quarentena/             # Ficheiros em quarentena
└── venv/                       # Ambiente virtual Python (criado automaticamente)
```

---

## 🐛 Resolução de Problemas

### Erro: "Flask não encontrado"

**Solução:**
```bash
source venv/bin/activate
pip install flask
```

### Erro: "Porta 5000 já em uso"

**Solução:**
```bash
# Usar outra porta
PORT=8080 ./start_interface.sh

# Ou terminar o processo
lsof -ti:5000 | xargs kill -9
```

### Erro: "Não consigo ligar ao Gmail"

**Verificar:**
1. Email e password estão corretos
2. Se usar Gmail, gere uma "App Password" (não a password normal)
3. A conta tem 2FA ativado? Gere App Password em: https://myaccount.google.com/apppasswords
4. Firewall não bloqueia conexões IMAP (porta 993)

### O Cron não executa

**Verificar:**
```bash
# Ver crontab atual
crontab -l

# Verificar logs do cron
tail -f logs/cron.log

# Verificar permissões
ls -l calma.sh
# Deve ter permissão de execução (x)
```

### Logs vazios ou desatualizados

**Solução:**
1. Clique em **🔄 Atualizar Logs** no separador Logs
2. Verifique se o script `calma.sh` tem permissão de execução
3. Verifique a pasta `logs/` existe e tem permissão de escrita

---

## 🔐 Segurança

### Práticas de Segurança Implementadas

1. **Passwords Mascaradas**: Passwords nunca são retornadas pela API
2. **Validação de Entrada**: Todos os inputs são validados
3. **Chave Secreta**: Flask usa uma chave secreta (mude em produção)
4. **HTTPS**: Em produção, coloque atrás de reverse proxy com SSL

### Recomendações para Produção

```bash
# 1. Gere uma chave secreta segura
python3 -c "import secrets; print(secrets.token_hex(32))"

# 2. Altere a chave em app.py (linha ~50)
app.secret_key = 'sua-chave-secura-gerada'

# 3. Use um servidor WSGI (ex: Gunicorn)
pip install gunicorn
gunicorn -w 4 -b 0.0.0.0:5000 app:app

# 4. Configure HTTPS com certificado SSL
```

---

## 📞 Suporte

Para problemas ou dúvidas:

1. Verifique os **Logs** na interface
2. Consulte os logs do sistema em `logs/`
3. Teste a conexão com o Gmail
4. Verifique as permissões dos ficheiros

---

## 📝 Licença

CALMA - Sistema Automático de Análise de Anexos
Todos os direitos reservados © 2025

---

**Desenvolvido com ❤️ para análise segura de anexos de email**
