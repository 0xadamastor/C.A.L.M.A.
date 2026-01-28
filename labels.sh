#!/bin/bash
# Script para criar as labels necessárias no Gmail

EMAIL_USER="calma.sandbox@gmail.com"
EMAIL_PASS="pujc jsmr ipln phnh"

echo "Criando labels no Gmail..."

python3 << END
import imaplib
import time

def create_gmail_labels():
    try:
        # Conectar ao Gmail
        mail = imaplib.IMAP4_SSL("imap.gmail.com", 993)
        mail.login("$EMAIL_USER", "$EMAIL_PASS")

        # Lista de labels a criar (SEM o prefixo INBOX/)
        labels = ["Infected", "Suspicious", "Clean", "Processed"]

        # Primeiro, apagar as labels antigas se existirem
        for label in labels:
            old_label = f"INBOX/{label}"
            try:
                mail.delete(old_label)
                print(f"  Removida label antiga: {old_label}")
                time.sleep(1)
            except:
                pass  # Ignora se não existir

        # Criar novas labels
        for label in labels:
            try:
                print(f"Criando label: {label}")

                # Criar mailbox (label no IMAP)
                mail.create(label)
                print(f"  ✓ Label '{label}' criada com sucesso")

                # Pequena pausa
                time.sleep(1)

            except Exception as e:
                error_msg = str(e)
                if "already exists" in error_msg or "EXISTS" in error_msg:
                    print(f"  ⓘ Label '{label}' já existe")
                else:
                    print(f"  ✗ Erro ao criar label '{label}': {e}")

        # Listar todas as labels disponíveis
        print("\nLabels disponíveis no Gmail:")
        status, folders = mail.list()
        if status == "OK":
            for folder in folders:
                folder_name = folder.decode()
                print(f"  - {folder_name}")

        mail.logout()
        print("\n✅ Labels configuradas com sucesso!")

    except Exception as e:
        print(f"ERRO: {e}")

create_gmail_labels()
END

echo ""
echo "Agora execute o script principal: ./calma.sh"
echo "Os emails serão automaticamente movidos para as labels apropriadas."
