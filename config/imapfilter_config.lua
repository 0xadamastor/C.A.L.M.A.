options.timeout = 120
options.subscribe = true

SERVER = 'imap.gmail.com'
USERNAME = 'email@gmail.com'
PASSWORD = 'xxxx xxxx xxxx xxxx'

account = IMAP {
    server = SERVER,
    username = USERNAME,
    password = PASSWORD,
    ssl = 'auto',
}

inbox = account.INBOX

-- Garantir que as labels existem no Gmail
account:create_mailbox('Infected')
account:create_mailbox('Clean')

infected_folder = account['Infected']
clean_folder    = account['Clean']

print('CALMA: IMAPFilter conectado ao Gmail com sucesso')
