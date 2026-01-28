#CALMA

**CALMA** is your paranoid email security guard. It automatically extracts, analyzes, and categorizes email attachments with the enthusiasm of a postal worker who's *really* concerned about what's in those packages. No more wondering if that "invoice.exe" from your "boss" is actually what it claims to be.

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

- **OS**: Something Unix-like (Linux, macOS running on borrowed time, etc.)
- **Bash**: Version 4.0+ (shouldn't be too hard to find)
- **Python**: 3.6 or newer (it's 2026, get with the times)
- **Gmail Account**: With IMAP turned on (your security team won't bite... much)
- **Internet**: For talking to Gmail's servers (they're surprisingly chatty)

## Let's Get This Thing Running

### Step 1: Get the Files

```bash
cd ~
git clone <repository-url> calma
cd calma
```

Or if you've already got the files sitting around:

```bash
cd /path/to/calma
```

### Step 2: Create the Gmail Labels (The Official Part)

CALMA needs three labels to exist in your Gmail account. Think of it as setting up the filing cabinet before the paperwork arrives.

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

### The Manual Way

```bash
./calma.sh
```

CALMA will then:

1. Double-check that Gmail labels exist (paranoia level: healthy)
2. Create folder structure if it doesn't exist
3. Ransack your inbox for unread emails with attachments
4. Extract and analyze each file with intensity
5. Assign each file to its destiny (Clean, Suspicious, or Infected)
6. Move the original emails into the right Gmail labels
7. File things away in the correct folders
8. Generate a fancy report (for your ego)
9. Delete old logs to free up space

### The Automated Way (Cron Jobs)

Want CALMA to run itself like a vigilant security daemon? Use cron:

#### Every Hour (The Constant Watcher)

```bash
crontab -e
```

Add:
```cron
0 * * * * /home/username/calma/calma.sh >> /home/username/calma/logs/cron.log 2>&1
```

#### Every 30 Minutes (The Paranoid Option)

```cron
*/30 * * * * /home/username/calma/calma.sh >> /home/username/calma/logs/cron.log 2>&1
```

#### Every 10 Minutes (This is Overkill but Sure)

```cron
*/10 * * * * /home/username/calma/calma.sh >> /home/username/calma/logs/cron.log 2>&1
```

Or just run the helper script:

```bash
chmod +x configurar_cron.sh
./configurar_cron.sh
```

## The File Organization Scheme

```
calma/
├── calma.sh                      # The Main Guy - runs the whole show
├── labels.sh                     # Creates Gmail labels (boring but necessary)
├── config.sh                     # Configuration helper (for the lazy)
├── configurar_cron.sh            # Sets up automatic running
├── README.md                     # This very document you're reading
├── logs/                         # Where CALMA keeps its diary
│   ├── execucao_*.log           # What happened this time
│   ├── relatorio_*.txt          # Pretty human-readable reports
│   └── email_map_*.txt          # Map of files to their original emails
└── dados/                        # Your processed files live here
    ├── anexos_processados/       # Extraction zone
    │   ├── a_analisar/          # "I haven't looked at this yet" folder
    │   ├── limpos/              # "This is boring and safe"
    │   └── infetados/           # "Burn it with fire"
    └── quarentena/              # The jail for suspicious stuff
```

## The Judgment System (How CALMA Decides Your File's Fate)

Think of CALMA as a bouncer at an exclusive club, but the club is your computer and the bouncers judge based on file type and sketchy behavior.

```
SCORE RANGE    │ VERDICT     │ WHAT HAPPENS
───────────────┼─────────────┼──────────────────────────────
0 - 29         │ CLEAN       │ Moved to "Clean" label
30 - 69        │ SUSPICIOUS  │ Moved to "Suspicious" label
70 - 100       │ INFECTED    │ Moved to "Infected" label
```

### The Scoring Rules (Why Files Get Judged Like This)

| File Type | Score Range | Reasoning |
|-----------|-------------|-----------|
| .exe, .bat, .dll, .scr | 80-100 | Windows executables are sus by default |
| .js, .jar, .vbs, .hta | 60-90 | Scripts that can mess with your system |
| .zip, .rar, .7z | 40-70 | Archives are like mystery boxes |
| .pdf, .doc, .xlsx | 20-60 | Office files can have macros (sneaky) |
| .mp3, .mp4, .jpg, .txt | 0-20 | Media files usually aren't trying to kill you |

### Filename-Based Red Flags (The Obvious Tells)

Some files just *announce* what they are:

- **"virus", "malware", "trojan", "ransomware", "exploit"** → Score: 85 (just no)
- **"suspicious", "danger"** → Score: 50 (we're looking...)
- **"safe", "clean", "example", "test"** → Score: 10 (probably okay)

## Check Your Reports (aka "Proof It's Working")

After CALMA runs, it leaves breadcrumbs everywhere:

```bash
# The latest report (the executive summary)
cat logs/relatorio_*.txt | tail -1

# Watch the execution log unfold (for debugging)
cat logs/execucao_*.log

# Stare at file metadata (if you're into that)
cat dados/anexos_processados/infetados/file.ext.meta
```

A typical metadata file looks like:
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

## Things Go Wrong (Troubleshooting)

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

1. **Never, EVER commit your Gmail credentials to Git**
   (Your password in a public repo is a security crime)

2. **Use App Passwords, not your main Gmail password**
   (App Passwords are like a key that only works for one door)

3. **Enable 2-Step Verification on your Google Account**
   (It's not optional, it's just smart)

4. **Check your logs regularly**
   (Weird activity? The logs will tell you)

5. **Keep backups of important emails**
   (Before CALMA deletes anything, back it up, just in case)

6. **Actually review the "Suspicious" folder**
   (Don't just blindly delete stuff - look at it first)

7. **Update your system regularly**
   (New security patches come out for a reason)

8. **Don't trust this blindly**
   (CALMA is a helper, not a guarantee. Real malware is sophisticated.)

## What This Is (And What It Isn't)

**CALMA Is:**
- A neat automation tool for email attachment management
- A heuristic-based classifier (educated guesses)
- A log-keeping auditor
- A Gmail organizer on steroids

**CALMA Is NOT:**
- A professional antivirus (it doesn't actually execute files)
- A guarantee against sophisticated malware
- A substitute for real security training
- A reason to stop being skeptical about email attachments

## Questions? Issues? Feature Requests?

1. Read the Troubleshooting section above first
2. Check your logs in `logs/` - they tell a story
3. Verify all configuration steps are complete
4. Make sure Gmail IMAP is actually enabled

---

**Version**: 1.0  
**Status**: "It works on my machine" (as of January 2026)  
**Warranty**: Absolutely none. Use at your own risk.  
**Attitude**: Built with paranoia and a healthy distrust of email attachments
