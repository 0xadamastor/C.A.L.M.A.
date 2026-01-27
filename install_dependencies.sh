#!/bin/bash

echo "Instalando dependências para CALMA..."

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
    sqlite3 \
    git \
    wget \
    unzip \
    file \
    hashdeep \
    python3-venv \
    clamtk \
    yara

pip3 install flask requests pandas python-magic watchdog

sudo apt install -y clamav clamav-daemon clamtk

sudo freshclam

sudo mkdir -p /opt/calma/{incoming,attachments,reports,quarantine,logs/{forensic,analysis,system}}
sudo chmod -R 755 /opt/calma

echo "Dependências instaladas!"
echo "Configure seu email em /opt/calma/config/fetchmailrc e /opt/calma/config/imapfilter_config.lua"
