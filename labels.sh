#!/bin/bash

EMAIL_USER="email@gmail.com"
EMAIL_PASS="xxxx xxxx xxxx xxxx"

echo "Criando labels no Gmail..."

python3 << END
import imaplib
import time

def create_gmail_labels():
    try:
        mail = imaplib.IMAP4_SSL("imap.gmail.com", 993)
        mail.login("$EMAIL_USER", "$EMAIL_PASS")

        labels = ["Infected", "Suspicious", "Clean", "Processed"]
        
        for label in labels:
            old_label = f"INBOX/{label}"
            try:
                mail.delete(old_label)
                print(f"  Removida label antiga: {old_label}")
                time.sleep(1)
            except:
                pass

        for label in labels:
            try:
                print(f"Criando label: {label}")

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

        print("\nLabels disponíveis no Gmail:")
        status, folders = mail.list()
        if status == "OK":
            for folder in folders:
                folder_name = folder.decode()
                print(f"  - {folder_name}")

        mail.logout()
        print("\nLabels configuradas com sucesso!")

    except Exception as e:
        print(f"ERRO: {e}")

create_gmail_labels()
END

echo ""
echo "Agora execute o script principal: ./calma.sh"
echo "Os emails serão automaticamente movidos para as labels apropriadas."
