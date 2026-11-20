#!/usr/bin/env bash
# 🔔 Сторож: каждые N секунд проверяет сервисы, при падении — ЗВУК + красная строка.
# Запуск:  ./healthcheck.sh            (бесконечно, раз в 10 с)
#          ./healthcheck.sh --once     (один проход, для проверки)
#          INTERVAL=5 ./healthcheck.sh services.conf
#          SERVICES_DIR=~/ad-train ./healthcheck.sh   (где лежат папки сервисов)
# При падении печатает готовые команды для копипаста: логи + откат из последнего сейва.
# ⚠️ имя в services.conf = имя папки сервиса (notes → $SERVICES_DIR/notes)

CONF="${1:-$(dirname "$0")/services.conf}"
[[ "$1" == "--once" ]] && { ONCE=1; CONF="$(dirname "$0")/services.conf"; }
INTERVAL="${INTERVAL:-10}"
SERVICES_DIR="${SERVICES_DIR:-$HOME/services}"
BACKUP_DIR="${BACKUP_DIR:-$HOME/backups}"
HERE="$(cd "$(dirname "$0")" && pwd)"
declare -A STATE   # имя -> UP/DOWN, чтобы орать только при СМЕНЕ состояния

alarm() {   # шумим всем, что есть на компе
  printf '\a'
  local s
  for s in /usr/share/sounds/freedesktop/stereo/alarm-clock-elapsed.oga \
           /usr/share/sounds/freedesktop/stereo/dialog-warning.oga \
           /usr/share/sounds/ocean/stereo/alarm-clock-elapsed.oga; do
    [[ -f $s ]] && command -v paplay >/dev/null && { paplay "$s" & break; }
  done
  command -v spd-say     >/dev/null && spd-say "$1 упал" &
  command -v notify-send >/dev/null && notify-send -u critical "💀 $1 DOWN" "$2"
}

hints() {   # готовые команды под упавший сервис — выдели мышкой и вставь
  local name=$1 dir="$SERVICES_DIR/$1" last
  # последний «нормальный» сейв (before-restore — это сломанное состояние, его не предлагаем)
  last=$(ls -t "$BACKUP_DIR/$name"-*.tgz 2>/dev/null | grep -v before-restore | head -1)
  printf '     🔍 cd %s && docker compose logs --tail 20\n' "$dir"
  if [[ -n $last ]]; then
    printf '     ⏪ %s/restore.sh %s %s\n' "$HERE" "$last" "$dir"
  else
    printf '     \e[33m⚠️  сейвов %s-*.tgz нет в %s — откатывать нечего!\e[0m\n' "$name" "$BACKUP_DIR"
  fi
}

check() {   # 0 = живой, 1 = мёртвый
  local host=$1 port=$2 path=$3
  if [[ -n $path ]]; then
    local code
    code=$(curl -s -o /dev/null -m 3 -w '%{http_code}' "http://$host:$port$path")
    [[ $code =~ ^[1-4][0-9][0-9]$ ]]        # 5xx или 000 (нет ответа) = плохо
  else
    nc -z -w 3 "$host" "$port" 2>/dev/null
  fi
}

while true; do
  clear 2>/dev/null; echo "🔔 healthcheck  $(TZ=Europe/Moscow date +%H:%M:%S)   (Ctrl+C — выход)"
  while read -r name host port path; do
    [[ -z $name || $name == \#* ]] && continue
    if check "$host" "$port" "$path"; then
      [[ ${STATE[$name]} == DOWN ]] && printf '\a'           # ожил — короткий бип
      STATE[$name]=UP;   printf '  \e[32m✅ %-10s %s:%s%s\e[0m\n' "$name" "$host" "$port" "$path"
    else
      [[ ${STATE[$name]} != DOWN ]] && alarm "$name" "$host:$port$path"
      STATE[$name]=DOWN; printf '  \e[31;1m💀 %-10s %s:%s%s  НЕ ОТВЕЧАЕТ\e[0m\n' "$name" "$host" "$port" "$path"
      hints "$name"
    fi
  done < "$CONF"
  [[ -n $ONCE ]] && break
  sleep "$INTERVAL"
done
