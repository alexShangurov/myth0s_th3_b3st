#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════════════╗
# ║ 🩹 redeploy.sh — выкатить патч от защитника БЕЗОПАСНО (ситуация «Б»)     ║
# ╠══════════════════════════════════════════════════════════════════════╣
# ║ ЗАЧЕМ:   защитник дал правку кода — надо собрать новый образ и поднять, ║
# ║          не потеряв возможность откатиться.                            ║
# ║ КОГДА:   каждый раз, когда патчишь сервис во время боя.                 ║
# ║ ШАГИ:    1) сейв кода before-<метка>  (НЕТ сейва → стоп, не катим)      ║
# ║          2) docker compose up -d --build                               ║
# ║          3) ищу CACHED на COPY → значит код НЕ уехал (жёлтое предупр.)  ║
# ║          4) docker compose ps — все ли Up                              ║
# ║          5) печатаю готовую строку отката, если табло покажет MUMBLE   ║
# ║ НЕ ДЕЛАЕТ: сам НЕ откатывает и НЕ трогает базу/данные. Решение за тобой.║
# ║ ОПАСНОСТЬ: низкая — перед сборкой всегда есть сейв. Но жди 1 раунд      ║
# ║           (2 мин) и смотри табло, прежде чем звать «готово».            ║
# ║ ПРИМЕР:  ./redeploy.sh ~/services/notes token-fix                      ║
# ╚══════════════════════════════════════════════════════════════════════╝
set -e
HERE="$(cd "$(dirname "$0")" && pwd)"
SRC="${1:?укажи папку сервиса, напр. ~/services/notes}"
NOTE="${2:?укажи метку патча, напр. token-fix}"
cd "$SRC"

echo "💾 1/4 сейв ДО патча..."
"$HERE/backup.sh" "$SRC" "before-$NOTE"      # нет сейва → set -e остановит, патч не катим

LOG="/tmp/redeploy-$(basename "$SRC")-$(TZ=Europe/Moscow date +%H%M%S).log"
echo "🔨 2/4 сборка и подъём (лог: $LOG)..."
docker compose up -d --build 2>&1 | tee "$LOG"

echo "🔍 3/4 проверка, что код уехал..."
# buildkit печатает шаг и CACHED РАЗНЫМИ строками (#8 [3/3] COPY… → #8 CACHED),
# старый формат — одной (=> CACHED [..] COPY). Ловим оба: COPY-шаг, помеченный CACHED.
if awk '
     /^#[0-9]+ .*COPY/        { split($1,a,"#"); copy[a[2]]=1 }
     /^#[0-9]+ CACHED$/       { split($1,a,"#"); if (copy[a[2]]) f=1 }
     /=> ?CACHED .*COPY/      { f=1 }
     END { exit f?0:1 }' "$LOG"; then
  printf '   \e[33m⚠️  CACHED на COPY — код мог НЕ уехать (старый образ)!\e[0m\n'
  printf '   \e[33m   правка точно в этой папке? попробуй: docker compose build --no-cache\e[0m\n'
else
  printf '   \e[32m✅ COPY не закэшен — новый код в образе\e[0m\n'
fi

echo "📦 4/4 статус контейнеров:"
docker compose ps
if docker compose ps --status running | grep -q .; then
  printf '   \e[32m✅ есть запущенные контейнеры\e[0m\n'
fi

LAST_OK=$(ls -t "${BACKUP_DIR:-$HOME/backups}/$(basename "$(realpath "$SRC")")"-*.tgz 2>/dev/null \
          | grep -v before- | head -1)
echo
echo "⏱️  ЖДИ 1 РАУНД (2 мин), смотри табло 10.10.10.10:"
echo "    • OK — готово, скажи защитнику ✅"
echo "    • MUMBLE/CORRUPT — патч сломал проверку, откатывай:"
if [[ -n $LAST_OK ]]; then
  echo "      $HERE/restore.sh $LAST_OK $SRC"
else
  printf '      \e[33m(чистого сейва orig пока нет — откат на before-%s)\e[0m\n' "$NOTE"
fi
