#!/bin/bash

echo "Instalando dependências para CALMA com Cuckoo Sandbox..."

sudo apt update && sudo apt upgrade -y

sudo apt install -y \
    fetchmail \
    munpack \
    curl \
    jq \
    imapfilter \
    cron \
    mailutils \
    python3 \
    python3-pip \
    python3-venv \
    python3-dev \
    sqlite3 \
    git \
    wget \
    unzip \
    file \
    hashdeep \
    build-essential \
    libssl-dev \
    libffi-dev \
    libjpeg-dev \
    zlib1g-dev \
    libpq-dev \
    virtualbox \
    virtualbox-ext-pack \
    tcpdump \
    libcap2-bin \
    genisoimage \
    git \
    supervisor \
    mongodb \
    libyara-dev \
    yara \
    clamav \
    clamav-daemon \
    ssdeep \
    libfuzzy-dev

echo "Instalando Cuckoo Sandbox..."
sudo pip3 install -U pip setuptools
sudo pip3 install -U cuckoo

cuckoo init --force

sudo mkdir -p /var/log/cuckoo
sudo chmod 755 /var/log/cuckoo

sudo usermod -a -G vboxusers $USER
sudo setcap cap_net_raw,cap_net_admin=eip /usr/sbin/tcpdump

echo "Baixando máquina virtual para análise..."
cd /opt
sudo wget https://cuckoo.sh/win7ultimate.zip -O /opt/win7ultimate.zip
sudo unzip /opt/win7ultimate.zip -d /opt/

VBoxManage registervm /opt/win7ultimate/win7ultimate.vbox
VBoxManage modifyvm "win7ultimate" --nictrace1 on
VBoxManage modifyvm "win7ultimate" --nictracefile1 "/opt/win7ultimate.pcap"

sudo mkdir -p /opt/calma/{incoming,attachments,reports,quarantine,logs/{forensic,analysis,system},config,sandbox}

sudo mkdir -p /opt/calma/sandbox/{pending,processing,completed,malicious,clean}
sudo chmod -R 755 /opt/calma

pip3 install flask requests pandas python-magic watchdog pydeep
pip3 install cuckoo

cd /opt/calma
sudo git clone https://github.com/cuckoosandbox/community.git /opt/calma/cuckoo-community

echo "Instalação concluída!"
echo "Configure:"
echo "1. Email em /opt/calma/config/fetchmailrc e /opt/calma/config/imapfilter_config.lua"
echo "2. Cuckoo: cuckoo --help"
echo "3. Inicie o Cuckoo: cuckoo -d"
