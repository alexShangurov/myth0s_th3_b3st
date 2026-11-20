# 🐳 Docker для Attack-Defense — шпаргалка команды

Контекст: сервисы на финале почти всегда лежат в `docker-compose`. Патчим файлы,
пересобираем контейнер, следим, чтобы сервис был жив (SLA). Этого набора хватает.

---

## 0. Где я? (первое, что делаешь)
```bash
docker ps                      # какие контейнеры живы сейчас
docker compose ps              # то же, но для текущего сервиса (из папки с compose)
docker compose config          # показать итоговый конфиг (порты, volume, env)
ls                             # ищи docker-compose.yml / Dockerfile
```

## 1. Поднять / положить сервис
```bash
docker compose up -d           # поднять в фоне
docker compose up -d --build   # пересобрать образ И поднять (после патча!)
docker compose down            # остановить и снести контейнеры
docker compose restart <имя>   # перезапустить один сервис
docker compose stop / start    # без удаления
```
⚠️ После правки кода нужен **--build**, иначе крутится старая версия.

## 2. Смотреть, что происходит (логи = твои глаза)
```bash
docker compose logs -f             # живой поток логов всех сервисов
docker compose logs -f <имя>       # одного
docker compose logs --tail=50 <имя> # последние 50 строк
```

## 3. Залезть внутрь контейнера (патчим код)
```bash
docker compose exec <имя> sh       # шелл внутри (или bash)
docker exec -it <id> sh            # по id, если без compose
# внутри: ls, cat, vi — найти файл сервиса
```
Чаще код лежит в **volume** (на хосте) → правишь файл на хосте, затем `up -d --build`
или `restart`. Смотри раздел `volumes:` в compose — там путь.

## 4. Проверить, не сломал ли (SLA!)
```bash
docker compose ps              # статус: Up / Exited / Restarting
docker compose logs --tail=30 <имя>  # нет ли traceback после патча
curl localhost:<порт>/         # сервис отвечает руками?
```
🛡️ Правило: **пропатчил → up -d --build → ps → logs → curl.** Только потом выдыхаешь.

## 5. Откат (всегда имей рабочую копию)
```bash
cp -r service service.bak      # ДО патча сделай бэкап папки
# если сломал:
cp -r service.bak/* service/ && docker compose up -d --build
```

## 6. Разное полезное
```bash
docker images                  # список образов
docker stats                   # нагрузка (CPU/RAM) по контейнерам
docker compose exec <имя> env  # посмотреть переменные (секреты?)
docker network ls              # сети (в A/D сервисы в своей сети)
docker system df               # сколько места ест docker
```

---

## 🔑 Мини-память (чтобы не поплыть)
- `ps` — кто жив
- `logs -f` — что происходит
- `exec … sh` — зайти внутрь
- `up -d --build` — применить патч
- `down` — всё снести
- **бэкап до патча, curl после патча**

## Типичные грабли A/D
- Забыл `--build` → патч не применился, дыру всё ещё эксплуатируют.
- `down` вместо `restart` → сервис лёг на раунды → DOWN 💀 → минус SLA.
- Поменял порт/убрал сервис в compose → чекер не достучался → DOWN.
- Правил внутри контейнера, не в volume → при пересборке правка исчезла.
