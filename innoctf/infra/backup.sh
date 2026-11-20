#!/usr/bin/env bash
# 💾 Бэкап КОДА сервиса перед патчем.
# ./backup.sh <папка_сервиса> [заметка]     пример: ./backup.sh ~/services/notes before-token-fix
# Архивы: ~/backups/<сервис>-<время>-<заметка>.tgz
set -e
SRC="${1:?укажи папку сервиса}"; NOTE="${2:-manual}"
DST="${BACKUP_DIR:-$HOME/backups}"; mkdir -p "$DST"
NAME=$(basename "$(realpath "$SRC")")
FILE="$DST/$NAME-$(TZ=Europe/Moscow date +%H%M%S)-$NOTE.tgz"
# данные (БД, флаги) НЕ берём — их откат = CORRUPT. Только код и конфиги.
tar czf "$FILE" -C "$(dirname "$(realpath "$SRC")")" \
    --exclude='*/data' --exclude='*/db' --exclude='*/pgdata' --exclude='*.sqlite*' --exclude='node_modules' "$NAME"
echo "✅ $FILE  ($(du -h "$FILE" | cut -f1))"
ls -1t "$DST" | grep "^$NAME-" | head -5 | sed 's/^/   /'
