#!/usr/bin/env bash
# 🔒 Первые 40 минут на вулнбоксе (сеть закрыта). Запускать НА ВУЛНБОКСЕ.
#   bash first40.sh scan      🔍 только смотрит: сервисы, порты, ключи, ssh
#   bash first40.sh backup    💾 сейв «orig» каждого docker-сервиса + SHA256SUMS
#   bash first40.sh verify    🔎 сейвы целы? сверка sha256 + tar tzf (12:55/перед откатом)
#   sudo bash first40.sh lock 🔐 выключить вход по паролю в ssh + проверка
# Руками остаётся: passwd, ssh-copy-id с ноута, удалить чужие ключи.
HERE="$(cd "$(dirname "$0")" && pwd)"
U="${SUDO_USER:-$USER}"; UHOME="$(getent passwd "$U" | cut -d: -f6)"

dirs() {   # папки всех compose-проектов, в том числе остановленных
  docker ps -a --format '{{.Label "com.docker.compose.project.working_dir"}}' 2>/dev/null | grep . | sort -u
}
keys() {   # тип + подпись каждого ключа (сам ключ не печатаем)
  local f
  for f in "$UHOME/.ssh/authorized_keys" /root/.ssh/authorized_keys; do
    echo "  $f:"
    sudo cat "$f" 2>/dev/null | grep -v '^#' | grep . | awk '{print "    " NR ") " $1 " " $NF}' || true
  done
}
pwauth() { sudo sshd -T 2>/dev/null | grep -iE '^(passwordauthentication|kbdinteractiveauthentication|permitrootlogin)'; }

case "$1" in
scan)
  echo "📦 КОНТЕЙНЕРЫ";        docker ps -a --format '  {{.Names}}\t{{.Status}}\t{{.Ports}}' 2>/dev/null || echo "  docker не отвечает"
  echo "📁 ПАПКИ СЕРВИСОВ";    dirs | sed 's/^/  /'
  echo "🚪 ПОРТЫ (0.0.0.0 и * = торчит наружу)"; sudo ss -tlnp | awk 'NR>1{print "  " $4 "\t" $NF}'
  echo "⚙️  СЕРВИСЫ НА ХОСТЕ (не Docker — ищи незнакомое)"
  systemctl list-units --type=service --state=running --no-legend | awk '{print "  " $1}'
  echo "🔑 КЛЮЧИ SSH (чужие удалить руками)"; keys
  echo "🔐 SSH СЕЙЧАС";        pwauth | sed 's/^/  /'
  echo "💽 ДИСК";              df -h / | sed 's/^/  /'
  ;;
backup)
  [[ -n "$(dirs)" ]] || { echo "❌ compose-сервисов не нашёл — смотри scan, сейв руками"; exit 1; }
  dirs | while read -r d; do bash "$HERE/backup.sh" "$d" orig; done
  BK="${BACKUP_DIR:-$HOME/backups}"
  ( cd "$BK" && sha256sum ./*.tgz > SHA256SUMS ) && echo "🔏 контрольные суммы → $BK/SHA256SUMS"
  echo "➡️  теперь копия к себе, С НОУТА:  scp -r $U@<VB>:~/backups ~/orig-backups"
  ;;
verify)
  BK="${BACKUP_DIR:-$HOME/backups}"
  [[ -f "$BK/SHA256SUMS" ]] || { echo "❌ нет $BK/SHA256SUMS — сначала first40.sh backup"; exit 1; }
  echo "🔎 сверка контрольных сумм:"
  ( cd "$BK" && sha256sum -c SHA256SUMS ) || { echo "❌ сейв изменился/побит — не доверяй!"; exit 1; }
  echo "🔎 архивы читаются целиком:"
  ok=1
  for f in "$BK"/*.tgz; do
    if tar tzf "$f" >/dev/null 2>&1; then printf '  ✅ %s\n' "$(basename "$f")"
    else printf '  \e[31m❌ %s — битый архив\e[0m\n' "$(basename "$f")"; ok=0; fi
  done
  [[ $ok -eq 1 ]] && echo "✅ все сейвы целы" || { echo "❌ есть битые — пересними backup.sh"; exit 1; }
  ;;
lock)
  [[ $EUID -eq 0 ]] || { echo "❌ нужен sudo"; exit 1; }
  [[ -s "$UHOME/.ssh/authorized_keys" ]] || { echo "❌ у $U нет ключей — сначала ssh-copy-id с ноута, иначе запрёшься снаружи"; exit 1; }
  echo "Ключи, которые останутся:"; keys
  read -rp "Зашёл по ключу во ВТОРОМ окне и оно работает? (yes) " a; [[ "$a" == yes ]] || exit 1
  # 00- читается первым, а в sshd побеждает ПЕРВОЕ значение → перебивает 50-cloud-init и т.п.
  printf 'PasswordAuthentication no\nKbdInteractiveAuthentication no\n' > /etc/ssh/sshd_config.d/00-innoctf.conf
  sshd -t || { rm -f /etc/ssh/sshd_config.d/00-innoctf.conf; echo "❌ конфиг кривой, откатил"; exit 1; }
  systemctl reload ssh 2>/dev/null || systemctl restart ssh || systemctl restart sshd
  echo "🔐 SSH ТЕПЕРЬ:"; pwauth | sed 's/^/  /'
  pwauth | grep -qi '^passwordauthentication no' && echo "✅ вход по паролю выключен" || echo "❌ НЕ выключился — смотри /etc/ssh/sshd_config"
  echo "➡️  проверь С НОУТА:  ssh -o PubkeyAuthentication=no $U@<VB>   → должно быть Permission denied"
  echo "⚠️  это окно не закрывай, пока проверка не прошла"
  ;;
*) sed -n '2,7p' "$0" ;;
esac
