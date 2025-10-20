#!/usr/bin/env bash
# EN: Backup script for backup-demo
# IT: Script di backup per il progetto backup-demo

set -euo pipefail
IFS=$'\n\t'

#####
# Variables / Variabili
#####
# EN: Flag set when an error occurs during the run
# IT: Flag impostato se si verifica un errore durante l'esecuzione
ERROR_OCCURRED=0

# EN: Buffer to store informational/debug messages; flushed only on error
# IT: Buffer per memorizzare messaggi informativi/debug; svuotato solo in caso di errore
declare -a LOG_BUFFER=()

# EN: LOG_FILE path read from config file; if empty disables file logging
# IT: Percorso LOG_FILE letto dal file config; se vuoto disabilita il log su file
: "${LOG_FILE:-}"

#####
# Helpers / Messaggi di aiuto
#####
# EN: Append message to internal buffer (info/debug)
# IT: Aggiunge un messaggio al buffer interno (info/debug)
buffer_msg() {
  local level="$1"; shift
  local msg="$*"
  local ts
  ts=$(date --iso-8601=seconds)
  LOG_BUFFER+=("[$ts] [$level] $msg")
  if [ -n "${LOG_FILE:-}" ]; then
    local log_dir
    log_dir=$(dirname "$LOG_FILE")
    mkdir -p "$log_dir" 2>/dev/null || true
    if touch "$LOG_FILE" 2>/dev/null && [ -w "$LOG_FILE" ]; then
      printf "[%s] [%s] %s\n" "$ts" "$level" "$msg" >> "$LOG_FILE"
    fi
  fi
}

# EN: Print message immediately to stdout and to LOG_FILE if possible (used for initial/final/errors)
# IT: Stampa immediatamente il messaggio su stdout e su LOG_FILE se possibile (usato per iniziale/finale/errori)
emit_immediate() {
  local level="$1"; shift
  local msg="$*"
  local ts
  ts=$(date --iso-8601=seconds)
  printf "[%s] [%s] %s\n" "$ts" "$level" "$msg"
  if [ -n "${LOG_FILE:-}" ]; then
    local log_dir
    log_dir=$(dirname "$LOG_FILE")
    mkdir -p "$log_dir" 2>/dev/null || true
    if touch "$LOG_FILE" 2>/dev/null && [ -w "$LOG_FILE" ]; then
      printf "[%s] [%s] %s\n" "$ts" "$level" "$msg" >> "$LOG_FILE"
    fi
  fi
}

# EN: Handle an error immediately: set flag and print buffered messages + error
# IT: Gestisce immediatamente un errore: imposta il flag e stampa i messaggi bufferizzati + l'errore
log_error() {
  local msg="$*"
  ERROR_OCCURRED=1

  if [ ${#LOG_BUFFER[@]} -gt 0 ]; then
    printf "\n" >&2
    printf "=== Buffered log (printed because of error) ===\n" >&2
    for line in "${LOG_BUFFER[@]}"; do
      printf "%s\n" "$line" >&2
    done
    printf "=== End buffered log ===\n\n" >&2
  fi

  emit_immediate "ERROR" "$msg"
}

#####
# Load config file / Caricamento del file config
#####
# EN: Load configuration file (expected in repo or via BACKUP_CONF env var)
# IT: Carica il file di configurazione (nella repo o tramite la variabile BACKUP_CONF)
CONFIG_FILE="$(dirname "$0")/../backup.conf"
if [ -n "${BACKUP_CONF:-}" ]; then
  CONFIG_FILE="$BACKUP_CONF"
fi

if [ ! -f "$CONFIG_FILE" ]; then
  emit_immediate "ERROR" "Config file not found: $CONFIG_FILE"
  exit 1
fi
# shellcheck disable=SC1090
source "$CONFIG_FILE"

#####
# Validate required configuration / Convalidare la configurazione richiesta
#####
# EN: Ensure required variables are set in the config file
# IT: Assicura che le variabili richieste siano impostate nel file di configurazione
: "${SOURCE_DIR:?SOURCE_DIR is not set in config}"
: "${BACKUP_DIR:?BACKUP_DIR is not set in config}"
: "${BACKUP_PREFIX:=backup_working}"
: "${KEEP_DAYS:=6}"

#####
# Pre-flight checks / Controllo pre inizializzazione script
#####
# EN: Create backup directory if it does not exist
# IT: Crea la cartella dei backup se non esiste
mkdir -p "$BACKUP_DIR"

# EN: Ensure readability/writability
# IT: Verifica permessi di lettura/scrittura
if [ ! -r "$SOURCE_DIR" ]; then
  log_error "SOURCE_DIR is not readable: $SOURCE_DIR"
  exit 2
else
  buffer_msg "INFO" "SOURCE_DIR is readable: $SOURCE_DIR"
fi

if [ ! -w "$BACKUP_DIR" ]; then
  log_error "BACKUP_DIR is not writable: $BACKUP_DIR"
  exit 3
else
  buffer_msg "INFO" "BACKUP_DIR is writable: $BACKUP_DIR"
fi

#####
# Lock handling (flock) / Controllo tramite un file .lock (flock)
#####
# EN: Use lockfile to prevent concurrent runs; clean up at exit
# IT: Usa lockfile per evitare esecuzioni concorrenti; si pulisce alla chiusura
LOCK_FILE="${BACKUP_DIR}/backup.lock"
LOCK_FD=200

# EN: Create/truncate lock file (best-effort)
# IT: Crea o tronca il file di lock (tentativo migliore)
: > "$LOCK_FILE" 2>/dev/null || {
  log_error "Cannot create or write to lock file: $LOCK_FILE"
  exit 4
}

# EN: Acquire exclusive non-blocking lock
# IT: Acquisisce un lock esclusivo non bloccante
exec {LOCK_FD}>"$LOCK_FILE" || {
  log_error "Cannot open lock descriptor: $LOCK_FILE"
  exit 5
}
if ! flock -n "$LOCK_FD"; then
  buffer_msg "INFO" "Another backup process is running. Exiting."
  exec {LOCK_FD}>&- || true
  exit 0
else
  buffer_msg "INFO" "Acquired lock: $LOCK_FILE"
fi

# EN: Cleanup function: release lock, remove lock file, decide success/error based on exit code
# IT: Funzione di pulizia: rilascia il lock, rimuove il file di lock, decide successo/errore in base al codice di uscita
_cleanup() {
  local exit_code=$?

  # Release lock by closing descriptor / Rilascia il blocco chiudendo il descrittore
  if [ -n "${LOCK_FD:-}" ]; then
    exec {LOCK_FD}>&- 2>/dev/null || true
  fi

  # Remove lock file (best-effort) / Rimuove il file di lock (tentativo migliore)
  if [ -f "$LOCK_FILE" ]; then
    rm -f "$LOCK_FILE" 2>/dev/null || true
  fi

  # EN: If non-zero exit code -> print buffered logs + error message
  # IT: Se il codice di uscita è diverso da zero -> stampa i log memorizzati nel buffer + messaggio di errore
  if [ "$exit_code" -ne 0 ]; then
    if [ ${#LOG_BUFFER[@]} -gt 0 ]; then
      printf "\n" >&2
      printf "=== Buffered log (printed because of error) ===\n" >&2
      for line in "${LOG_BUFFER[@]}"; do
        printf "%s\n" "$line" >&2
      done
      printf "=== End buffered log ===\n\n" >&2
    fi
    emit_immediate "ERROR" "Backup script exited with code $exit_code"
    exit $exit_code
  fi

  # EN: If exit code == 0 -> success: print final success message if no error
  # IT: Se l'exit code è uguale a 0, stampa su schermo che è andato a buon fine
  emit_immediate "INFO" "Backup completed successfully. You can find it at:"
  printf "%s\n" "$BACKUP_DIR"
  exit 0
}
trap _cleanup EXIT HUP INT TERM

#####
# Filenames and tmp files / Nomi dei file e file tmp
#####
# EN: Compute today's date and filenames
# IT: Calcola la data odierna e i nomi dei file
TODAY=$(date +%F)
TARFILE_BASE="${BACKUP_PREFIX}_${TODAY}"
TARFILE_UNCOMPRESSED="${BACKUP_DIR}/${TARFILE_BASE}.tar"
TMP_TAR="${TARFILE_UNCOMPRESSED}.tmp"

# EN: Print initial message (always visible)
# IT: Stampa messaggio iniziale (visibile sempre)
emit_immediate "INFO" "Backup of directory ${SOURCE_DIR} in progress..."

#####
# Create uncompressed tar / Crea un archivio non compresso .tar
#####
# EN: Create tar of SOURCE_DIR into TMP_TAR
# IT: Crea il tar di SOURCE_DIR in TMP_TAR
buffer_msg "INFO" "Creating tar archive: $TARFILE_UNCOMPRESSED"
if ! tar -C "$SOURCE_DIR" -cf "$TMP_TAR" .; then
  log_error "tar creation failed for $SOURCE_DIR -> $TMP_TAR"
  exit 6
fi

if ! mv -f "$TMP_TAR" "$TARFILE_UNCOMPRESSED"; then
  log_error "Failed to move temp tar to final location: $TMP_TAR -> $TARFILE_UNCOMPRESSED"
  exit 7
fi
buffer_msg "INFO" "Created $TARFILE_UNCOMPRESSED"

#####
# Compression and rotation based on filename dates / Compressione e rotazione in base alle date dei nomi dei file
#####
# EN: Compress and rotate backups using the date embedded in filenames
# IT: Comprimi e ruota i backup usando la data incorporata nei nomi dei file

# Gather all matches / Raccogli tutte le corrispondenze (both .tar and .tar.gz)
shopt -s nullglob
all_matches=( "${BACKUP_DIR}/${BACKUP_PREFIX}"_* )
shopt -u nullglob

# Extract dates / Data esatta
declare -a DATES=()
for p in "${all_matches[@]}"; do
  if [[ $(basename "$p") =~ ${BACKUP_PREFIX}_([0-9]{4}-[0-9]{2}-[0-9]{2}) ]]; then
    DATES+=("${BASH_REMATCH[1]}")
  fi
done

# Duplicate and sort (newest first) / Duplica e ordina (prima il più recente)
if [ ${#DATES[@]} -gt 0 ]; then
  mapfile -t DATES < <(printf "%s\n" "${DATES[@]}" | sort -u -r)
fi
buffer_msg "DEBUG" "Found backup dates (newest first): ${DATES[*]:-<none>}"

NUM_DATES=${#DATES[@]}
buffer_msg "DEBUG" "Number of unique dates found: $NUM_DATES"

if [ "$NUM_DATES" -gt "$KEEP_DAYS" ]; then
  NUM_TO_DELETE=$((NUM_DATES - KEEP_DAYS))
  DELETES=( "${DATES[@]: -NUM_TO_DELETE}" )
else
  DELETES=()
fi

NEWEST_DATE="${DATES[0]:-}"
buffer_msg "DEBUG" "Newest date considered: ${NEWEST_DATE:-<none>}"

# Compress older .tar files (keep NEWEST_DATE uncompressed) / Comprimi i file .tar più vecchi (mantieni il più recente non compresso)
shopt -s nullglob
for tarfile in "${BACKUP_DIR}/${BACKUP_PREFIX}"_*.tar; do
  if [[ $(basename "$tarfile") =~ ${BACKUP_PREFIX}_([0-9]{4}-[0-9]{2}-[0-9]{2})\.tar$ ]]; then
    file_date="${BASH_REMATCH[1]}"
  else
    buffer_msg "DEBUG" "Skipping non-matching tar file: $tarfile"
    continue
  fi

  if [ "$file_date" = "$NEWEST_DATE" ]; then
    buffer_msg "DEBUG" "Keeping newest date uncompressed: $tarfile"
    continue
  fi

  if [ -f "${tarfile}.gz" ]; then
    buffer_msg "DEBUG" "Already compressed, skipping: ${tarfile}.gz"
    continue
  fi

  if [ ! -r "$tarfile" ] || [ ! -w "$tarfile" ]; then
    log_error "Insufficient permissions to compress $tarfile"
    continue
  fi

  buffer_msg "INFO" "Compressing: $tarfile -> ${tarfile}.gz"
  if ! gzip -9 "$tarfile"; then
    log_error "gzip failed for $tarfile; original left in place"
    continue
  fi
  buffer_msg "INFO" "Compression succeeded: ${tarfile}.gz"
done
shopt -u nullglob

# Delete oldest dates beyond KEEP_DAYS / Elimina le date più vecchie oltre il KEEP_DAYS
if [ ${#DELETES[@]} -gt 0 ]; then
  buffer_msg "INFO" "Deleting oldest dates: ${DELETES[*]}"
  for d in "${DELETES[@]}"; do
    rm -f "${BACKUP_DIR}/${BACKUP_PREFIX}_${d}.tar" "${BACKUP_DIR}/${BACKUP_PREFIX}_${d}.tar.gz" || {
      log_error "Failed to remove files for date ${d} (check permissions)"
      continue
    }
    buffer_msg "INFO" "Removed backups for date: $d"
  done
else
  buffer_msg "DEBUG" "No old dates to delete. Total dates: $NUM_DATES, keep: $KEEP_DAYS"
fi

# End: trap will run _cleanup and will show final message only if exit_code == 0
exit 0

