# CALMA - Containerized Automated Lazy Mail Anti-nasties

**CALMA** is your paranoid email security guard. It automatically extracts, analyzes, and categorizes email attachments with the enthusiasm of a postal worker who's *really* concerned about what's in those packages. No more wondering if that "invoice.exe" from your "boss" is actually what it claims to be.

## Quick Start - 30 Second Installation

The beautiful part about CALMA's installer is that it works everywhere. No more "it doesn't work on my machine" excuses.

### On Linux or macOS:
```bash
cd calma
./install.sh
```

###  Windows:
```bash
cd calma
install.bat
```

Or if you want to be fancy (works on any OS):
```bash
python3 install.py
```

**The installer will do the boring work for you:**
- Verifies you have Python 3.8+ installed (complains loudly if not)
- Creates a virtual environment called `venv` (to not mess with your system)
- Installs all dependencies from requirements.txt
- Creates the necessary folder structure
- Verifies everything worked (spoiler: it does)
- Shows you how to run CALMA

Basically, it's like an electrician who comes to your house, does everything, and then leaves you a manual with the invoice. But free.

---

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

## What You'll Need

- **OS**: Windows, macOS, Linux - any of them work (finally, equality!)
- **Python**: 3.8 or newer (the installer checks for you)
- **Bash Interpreter** (for manual scripts, optional if you use the web UI)
- **Internet**: To talk to Gmail or analyze files online

## Let's Get This Thing Running

### Step 1: Run the Installer (Even This Is Easy)

```bash
cd ~
git clone <repository-url> calma
cd calma
python3 install.py
```

And that's it. The installer does everything. Go make coffee.

### Step 2: Activate the Virtual Environment

```bash
# Linux or macOS
source venv/bin/activate

# Windows
venv\Scripts\activate
```

### Step 3: Run CALMA

```bash
python3 app.py
```

Visit http://localhost:5000 and start using it. Happy?

## Advanced Configuration (Optional)

If you want to use automatic email features:

### Create the Gmail Labels

CALMA needs three labels to exist in your Gmail account. Think of it as setting up the filing cabinet before the paperwork arrives.

## Time to Actually Run This Thing

### Web Interface

Yes, CALMA has a web interface. You don't need to run terminal scripts like a hacker from the 90s (although it's cool). The web UI is prettier, more intuitive, and doesn't make it look like you're hacking into Area 51:

- Upload files for analysis
- Analysis history
- Statistics and reports
- Real-time logs
- Configuration through the UI

### Manual Scripts (For the Nostalgic)

If you prefer the old school way, you still have the bash scripts:

```bash
./calma.sh
```

CALMA will then:

1. Double-check that Gmail labels exist (paranoia level: healthy)
2. Create folder structure if it doesn't exist
3. Hunt for unread emails with attachments
4. Extract and analyze each file with intensity
5. Assign each file its destiny (Clean, Suspicious, or Infected)
6. Move the emails to the right Gmail labels
7. File things away in the correct folders
8. Generate a beautiful report
9. Delete old logs before your disk explodes

### Automation with Cron (The Lazy Way)

Want CALMA to run itself like a paranoid daemon? Use cron:

#### Every Hour (The Constant Watcher)

```bash
crontab -e
```

Add:
```cron
0 * * * * /home/username/calma/venv/bin/python /home/username/calma/app.py >> /home/username/calma/logs/cron.log 2>&1
```

#### Every 30 Minutes (The Paranoid Option)

```cron
*/30 * * * * /home/username/calma/venv/bin/python /home/username/calma/app.py >> /home/username/calma/logs/cron.log 2>&1
```

#### Every 10 Minutes (This Is Overkill But Sure)

```cron
*/10 * * * * /home/username/calma/venv/bin/python /home/username/calma/app.py >> /home/username/calma/logs/cron.log 2>&1
```

Or just run the helper script:

```bash
chmod +x configurar_cron.sh
./configurar_cron.sh
```

## Project Structure

```
calma/
├── install.py                    # Cross-platform installer (runs on any OS)
├── install.sh                    # Wrapper script for Linux/macOS
├── install.bat                   # Wrapper script for Windows
├── app.py                        # Python API and web interface
├── requirements.txt              # Python dependencies (updated for compatibility)
├── venv/                         # Virtual environment (created by installer)
├── calma.sh                      # Email analysis script (optional)
├── labels.sh                     # Creates Gmail labels (optional)
├── config.sh                     # Configuration helper (optional)
├── README.md                     # This document
├── logs/                         # Execution history
├── dados/                        # Processed files
│   ├── anexos_processados/
│   │   ├── a_analisar/
│   │   ├── limpos/
│   │   ├── suspeitos/
│   │   └── infetados/
│   └── quarentena/
└── templates/                    # HTML templates for web UI
```

## The Judgment System (How CALMA Decides Your File's Fate)

Think of CALMA as a bouncer at an exclusive club, but the club is your computer and the bouncers judge based on file type and sketchy behavior.

```
SCORE RANGE    │ VERDICT     │ WHAT HAPPENS
───────────────┼─────────────┼──────────────────────────
0 - 29         │ CLEAN       │ File is okay with me
30 - 69        │ SUSPICIOUS  │ That's sketchy...
70 - 100       │ INFECTED    │ Burn it with fire
```

### Scoring Rules (Why Files Get Judged Like This)

| File Type | Score | Because? |
|---|---|---|
| .exe, .bat, .dll, .scr | 80-100 | Windows executables are sus by default |
| .js, .jar, .vbs, .hta | 60-90 | Scripts can mess with your system |
| .zip, .rar, .7z | 40-70 | Archives are like mystery boxes |
| .pdf, .doc, .xlsx | 20-60 | Office files can have macros (sneaky) |
| .mp3, .mp4, .jpg, .txt | 0-20 | Media files usually aren't trying to kill you |

### Red Flags in Filenames (The Obvious Tells)

Some files just *announce* what they are:

- **"virus", "malware", "trojan", "ransomware"** → Score: 85 (just no)
- **"suspicious", "danger"** → Score: 50 (we're looking...)
- **"safe", "clean", "example"** → Score: 10 (probably ok)

## Check Your Reports (aka "Proof It's Working")

After CALMA runs, it leaves breadcrumbs everywhere:

```bash
# The latest report
cat logs/relatorio_*.txt | tail -1

# Watch the execution log (for debugging)
tail -f logs/execucao_*.log

# Look at file metadata (if you're into that)
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

### "Authentication failed" / "Login credentials invalid"

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
=== FILE METADATA ===
Filename: document.pdf
Hash (sha256): a1b2c3d4e5f6...
Size: 2048576 bytes
Email from: sender@example.com
Extracted: 2026-01-28 15:30:45
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
