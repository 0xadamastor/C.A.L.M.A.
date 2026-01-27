options.timeout = 120
options.subscribe = true

SERVER = 'imap.gmail.com'
USERNAME = 'email@gmail.com'
PASSWORD = 'senha'

account = IMAP {
    server = SERVER,
    username = USERNAME,
    password = PASSWORD,
    ssl = 'tls1',
    port = 993,
}

inbox = account['INBOX']

infected_folder = account['Infected']
if infected_folder == nil then
    infected_folder = account:create_mailbox('Infected')
    print('CALMA: Pasta Infected criada')
    end

    clean_folder = account['Clean']
    if clean_folder == nil then
        clean_folder = account:create_mailbox('Clean')
        print('CALMA: Pasta Clean criada')
        end

        print('CALMA: Configuração IMAPFilter carregada')
