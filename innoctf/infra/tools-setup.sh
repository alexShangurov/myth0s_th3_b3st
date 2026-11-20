#!/usr/bin/env bash
# 🧰 Скачать тулзы ЗАРАНЕЕ (дома, с интернетом) → потом на флешку.
# Ссылки сверены со списком Re2 (чат команды, 17.11).
set -e
mkdir -p ~/ad-tools && cd ~/ad-tools
get() {   # клонировать, только если папки ещё нет (можно запускать повторно)
  if [[ -d $2 ]]; then echo "⏭️  $2 уже есть — пропускаю"; else git clone "$1" "$2"; fi
}
get https://github.com/C4T-BuT-S4D/S4DFarm         S4DFarm           # ферма флагов (веб-морда + сабмит в жюри)
get https://gitlab.com/packmate/starter.git        packmate-starter  # Packmate: «Wireshark, но удобнее для AD»
get https://github.com/ByteLeMani/ctf_proxy        ctf_proxy         # прокси-фильтр: быстро закрыть дыру, не трогая код
get https://github.com/C4T-BuT-S4D/neo             neo               # раннер эксплоитов (команда решила: не основной, «слишком сложно»)
echo "✅ склонировано в ~/ad-tools"
echo "Дальше в каждой папке: прочитать README, docker compose pull / build,"
echo "и сохранить образы для офлайна (по ИМЕНАМ, чтобы теги не потерялись):"
echo "  docker save -o ~/ad-tools/images.tar \$(docker images --format '{{.Repository}}:{{.Tag}}' | grep -v '<none>')"
echo "На месте:  docker load -i images.tar"
echo
echo "━━━ 🚩 ФЕРМА ФЛАГОВ S4DFarm — твоя зона (инфра, НЕ эксплойты) ━━━"
echo "Ферма = почта: атакующие кладут флаги в очередь, ферма шлёт их жюри и ретраит."
echo "Что настраиваешь ТЫ (поднять и чтобы флаги уходили), в server/config.py:"
echo "  • SYSTEM_PROTOCOL / TEAM_TOKEN — протокол сдачи и токен нашей команды (спросить у капитана)"
echo "  • адрес приёмника флагов жюри — 10.10.10.10 (порт из правил финала)"
echo "  • FLAG_FORMAT, FLAG_LIFETIME=5 раундов, SUBMIT_PERIOD — по брифингу"
echo "Запуск:   cd ~/ad-tools/S4DFarm && docker compose up -d   (веб-морда локально)"
echo "Проверка: открой веб-морду → вкладка со статусами; тестовый флаг должен"
echo "          пройти QUEUED → ACCEPTED/REJECTED, а не висеть. Ретраи сами."
echo "Сейв:     backup.sh ~/ad-tools/S4DFarm farm-config   (сохрани рабочий конфиг)"
echo "⚠️  порт веб-морды наружу не открывать: 127.0.0.1:PORT в compose (как у сервисов)."
