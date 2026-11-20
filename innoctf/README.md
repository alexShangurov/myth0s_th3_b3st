# 📁 INNOCTF Junior — набор по Attack-Defense (для флешки)

Финал 21.11, AD на ForcAD. Роль Лешего — инфраструктурщик 🏗️

## Что здесь лежит
| Файл | Про что | Для кого |
|---|---|---|
| `docker-cheatsheet.md` | команды docker/compose, патч без потери SLA | все, особенно инфра |
| `vuln-checklist.md` | 13 классов уязвимостей: признак → фикс | защитники |
| `ad-concepts.md` | как устроена AD: раунды, вердикты, флаги, ферма | все новички |

## 🏗️ infra/ — заготовки инфраструктурщика (готово 17.11)
- [x] `templates/` — compose-шаблоны: python-web, node-web, tcp-binary, db-postgres
- [x] `healthcheck.sh` + `services.conf` — сторож сервисов, звук при падении 🔔
- [x] `backup.sh` / `restore.sh` — бэкап кода до патча, откат одной командой
- [x] `backup-policy.md` — правила бэкапов для всей команды
- [x] `tools-setup.sh` — склонировать S4DFarm, Neo, Packmate, ctf_proxy
- [ ] прогнать `tools-setup.sh` дома + `docker save` образов на флешку

## Тулзы (склонировать заранее)
- S4DFarm — ферма флагов
- Packmate — анализ пакетов (удобнее Wireshark для AD)
- ctf_proxy — быстро закрывать уязвимости прокси
- Neo — раннер эксплойтов
