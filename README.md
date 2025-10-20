# Backup Automation Demo

**EN:**  
This project demonstrates a complete, professional backup automation system written in **Bash**, with clear documentation, configurable parameters, and optional **Docker containerization**.  
It’s designed to showcase scripting, automation, and DevOps best practices — ideal as a portfolio project or a practical daily tool.

**IT:**  
Questo progetto dimostra un sistema completo e professionale di automazione dei backup scritto in **Bash**, con documentazione chiara, parametri configurabili e possibilità di eseguirlo in **Docker**.  
È progettato per mostrare competenze reali in scripting, automazione e DevOps — perfetto come progetto dimostrativo o strumento reale.

---

## Features / Funzionalità

**EN**
- Daily backup of a target folder (default: `~/working`)
- Automatic naming using format: `backup_working_YYYY-MM-DD`
- Keeps **6 latest backups**:
  - The latest one **uncompressed** (for fast restore)
  - The 5 older backups **compressed** (to save space)
- Auto-deletion of older archives
- Configuration file for easy customization
- Works both on host and inside a Docker container
- Cron-based daily scheduling at 17:50

**IT**
- Backup giornaliero di una cartella target (default: `~/working`)
- Nomi automatici nel formato: `backup_working_YYYY-MM-DD`
- Mantiene **gli ultimi 6 backup**:
  - L’ultimo **non compresso** (per un ripristino veloce)
  - I 5 più vecchi **compressi** (per risparmiare spazio)
- Eliminazione automatica dei backup più vecchi
- File di configurazione per modificare facilmente le cartelle
- Funziona sia su host che in container Docker
- Pianificazione giornaliera automatica alle 17:50 con `cron`

---

## Project Structure / Struttura del progetto

```
backup-demo/
├── scripts/
│   └── backup.sh              # Main backup script / Script di backup principale
├── backup.conf.example        # Config file example / Configurazione esempio del file
├── backup.conf                # Real config file / Configurazione effettiva del file
├── docs/
│   └── usage_quick.md         # Quick usage guide / Guida rapida all'uso
├── LICENSE
└── README.md
```

---

## Setup on Host / Configurazione su Host

### 1. Clone the project / Clona il progetto
**EN**
```bash
git clone git@github.com:YourUsername/backup-demo.git
cd backup-demo
```

**IT**
```bash
git clone git@github.com:IlTuoNomeUtente/backup-demo.git
cd backup-demo
```

---

### 2. Configure the backup paths / Configurare i percorsi di backup
**EN**
Copy the example config file and edit it:
```bash
cp backup.conf.example backup.conf
nano backup.conf
```

Inside, set:
```bash
SOURCE_DIR="/home/username/working"
BACKUP_DIR="/home/username/backup"
```

*Ensure both folders exist and the user has write permissions.*

**IT**
Copia il file di configurazione di esempio e modificalo:
```bash
cp backup.conf.example backup.conf
nano backup.conf
```

All’interno, imposta i percorsi:
```bash
SOURCE_DIR="/home/username/working"
BACKUP_DIR="/home/username/backup"
```

*Assicurati che entrambe le cartelle esistano e che l’utente abbia i permessi di scrittura.*

---

### 3. Set permissions / Imposta i permessi
**EN:** The script must be executable.  
**IT:** Lo script deve avere permessi di esecuzione.

```bash
chmod +x scripts/backup.sh
```

If using the config file / Se usi il file di configurazione:
```bash
chmod 600 backup.conf
```

---

### 4. Test manually / Test manuale
**EN:** Run once manually to verify that it works.  
**IT:** Esegui una volta manualmente per verificare che funzioni.

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

### 5. Schedule with cron / Automatizza con cron
**EN:** Open the crontab editor:  
**IT:** Apri l’editor di cron:

```bash
crontab -e
```

Add this line using the right path / Aggiungi questa linea usando il percorso corretto:
```bash
50 17 * * * /path/to/backup-demo/scripts/backup.sh >> /path/to/backup-demo/backup.log 2>&1
```

*This will run the backup every day at 17:50 (5.50 P.M.). / Questo avvierà il backup ogni giorno alle ore 17:50*

To list your cron jobs / Per elencare i tuoi cron job:
```bash
crontab -l
```

---

## Cleanup / Pulizia
To remove old backups manually / Per rimuovere manualmente i vecchi backup:
```bash
rm -f /home/username/backup/backup_working_*.tar*
```

---

## Notes / Note finali

**EN:**
- The uncompressed archive is always the latest one.
- Previous ones are automatically compressed.
- The 7th (oldest) backup is automatically deleted.

**IT:**
- L’archivio non compresso è sempre l’ultimo creato.
- I precedenti vengono compressi automaticamente.
- Il settimo backup (più vecchio) viene eliminato.

---

## License

**EN:**
Licensed under the MIT License.  
See `LICENSE` for details.

**IT:**
Concesso in licenza con licenza MIT.
Vedi `LICENSE` per i dettagli.
