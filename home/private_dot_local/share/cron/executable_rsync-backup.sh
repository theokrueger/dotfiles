#!/bin/bash
# copies from <source> to <dest> using rsync
# dependencies: rsync
# cron settings:
# 00 04 * * * /bin/bash ~/.local/share/cron/rsync-backup.sh <source> <dest>
# every day at 4am

LOGFILE="$(dirname "$0")/log"
SOURCE="$1"
DEST="$2"

log() {
    echo "[$(date "+%F %R")] $@" >> "$LOGFILE"
}

SOURCE_TO_DEST="\"$SOURCE\" to \"$DEST\""

log "Starting rsync backup from $SOURCE_TO_DEST"

if [ -d "$DEST"  ] && [ -d "$SOURCE" ] && \
       rsync --checksum --recursive --human-readable "$SOURCE" "$DEST"; then
    log "Successfully ran rsync backup $SOURCE_TO_DEST"
else
    log "Error running rsync backup $SOURCE_TO_DEST"
fi
