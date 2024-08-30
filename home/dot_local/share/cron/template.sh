#!/bin/bash
# short description of the script
# dependencies: none
# cron settings:
# 00 00 * * * /bin/bash ~/.local/share/cron/rsync-backup.sh <source> <dest>
# every day at 12am

LOGFILE="$(dirname "$0")/log"

log() {
    echo "[$(date "+%F %R")] $@" >> "$LOGFILE"
}

log "Successfully the cron template"
