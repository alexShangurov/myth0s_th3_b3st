#!/usr/bin/env bash
# ⏪ Откат кода сервиса из бэкапа + пересборка.
# ./restore.sh <архив.tgz> <папка_сервиса>
set -e
ARC="${1:?архив}"; SRC="${2:?папка сервиса}"
"$(dirname "$0")/backup.sh" "$SRC" before-restore      # сначала бэкап текущего (вдруг откат зря)
tar xzf "$ARC" -C "$(dirname "$(realpath "$SRC")")"
cd "$SRC" && docker compose up -d --build && docker compose ps
echo "⏪ откатил из $ARC — проверь чекер/healthcheck!"
