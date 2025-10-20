# Quick Usage Guide / Guida rapida all'uso

**EN:**
This file provides a fast overview of how to use the Backup Demo project — ideal for recruiters or users who want to see the project in action without reading the full README.

**IT:**
Questo file fornisce una panoramica rapida su come usare il progetto Backup Demo — ideale per recruiter o utenti che vogliono vedere il progetto in azione senza leggere tutto il README.

---

## Quick Start / Avvio rapido

### 1: Clone and configure / Clona e configura
```bash
git clone git@github.com:YourUsername/backup-demo.git
cd backup-demo
cp backup.conf.example backup.conf
```

Edit the config file / Modifica il file di configurazione:
```bash
nano backup.conf
```
Set your paths:
```
SOURCE_DIR="/home/username/working"
BACKUP_DIR="/home/username/backup"
```

---

### 2: Make executable / Rendi eseguibili i file
```bash
chmod +x scripts/backup.sh
chmod 600 backup.conf
```

---

### 3: Test backup manually / Prova il backup manuale
```bash
./scripts/backup.sh
```
Expected output / Output previsto:
```
[2025-10-20T11:34:42+02:00] [INFO] Backup of directory /home/user/working in progress...
[2025-10-20T11:34:43+02:00] [INFO] Backup completed successfully. You can find it at:
/home/user/backup
```

---

### 4: Automate with cron / Automatizza con cron
Open the crontab / Apri crontab:
```bash
crontab -e
```

Add this line using the right path / Aggiungi questa linea usando il percorso corretto:
```
50 17 * * * /path/to/backup-demo/scripts/backup.sh >> /path/to/backup-demo/backup.log 2>&1
```

This runs the backup every day at 17:50 / Questo esegue il backup ogni giorno alle 17:50.

---

## Maintenance / Manutenzione

| Task | Command |
|------|----------|
| View cron jobs / Elenco dei cron jobs | `crontab -l` |
| View logs / Guarda i log | `cat backup.log` |
| Remove all backups / Elimina tutti i backup | `rm -f /home/username/backup/backup_working_*.tar*` |

---

## Tip / Suggerimento
**EN:** To simulate a daily run, temporarily change the cron time to 2 minutes ahead and wait.  
**IT:** Per simulare un’esecuzione giornaliera, cambia temporaneamente l’orario di cron a 2 minuti nel futuro e attendi.

---

## Contact / Contatti
**EN**
For questions or improvements, open an issue on GitHub or fork the repo.
**IT:**
Per domande o miglioramenti, apri un problema su GitHub o esegui un fork del repository.
