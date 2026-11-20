#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════════════╗
# ║ 📋 collect-logs.sh — собрать всё про сервис в ОДИН файл для защитника   ║
# ╠══════════════════════════════════════════════════════════════════════╣
# ║ ЗАЧЕМ:   защитник просит «покажи, что с сервисом» — не пересказывай     ║
# ║          словами, отдай файл.                                          ║
# ║ КОГДА:   сервис тупит, защитник анализирует атаку, разбор после DOWN.   ║
# ║ ШАГИ:    складывает в ~/logs/<сервис>-<ЧЧММ>.txt:                       ║
# ║            docker compose ps · logs --tail 200 · df -h · docker stats   ║
# ║ НЕ ДЕЛАЕТ: ничего не меняет — только читает. Данные/флаги не трогает.   ║
# ║ ОПАСНОСТЬ: нет, безопасен.                                             ║
# ║ ПРИМЕР:  ./collect-logs.sh ~/services/notes                            ║
# ╚══════════════════════════════════════════════════════════════════════╝
set -e
SRC="${1:?укажи папку сервиса, напр. ~/services/notes}"
NAME=$(basename "$(realpath "$SRC")")
DST="${LOG_DIR:-$HOME/logs}"; mkdir -p "$DST"
OUT="$DST/$NAME-$(TZ=Europe/Moscow date +%H%M).txt"
cd "$SRC"

{
  echo "===== $NAME @ $(TZ=Europe/Moscow date '+%d.%m %H:%M:%S') ====="
  echo; echo "----- docker compose ps -----";          docker compose ps
  echo; echo "----- logs --tail 200 -----";            docker compose logs --tail 200
  echo; echo "----- df -h -----";                       df -h
  echo; echo "----- docker stats (снимок) -----";       docker stats --no-stream
} > "$OUT" 2>&1

echo "✅ $OUT  ($(wc -l < "$OUT") строк)"
echo "➡️  отдай файл защитнику: scp $USER@<VB>:$OUT ."
