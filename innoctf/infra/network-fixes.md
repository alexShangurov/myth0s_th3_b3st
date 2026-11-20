# 🩹 Сборка падает из-за сети: 3 лекарства (проверено 19.11 на S4DFarm)

Признак: `timeout`, `TLS handshake timeout`, `Read timed out`, `from versions: none`.
Значит, виноват не код, а «магазин закрыт». Покупаем в соседнем 🏪

Сначала просто повторить `docker compose build`: готовые шаги возьмутся из кэша.

| Что падает | Строка в Dockerfile, ПЕРЕД упавшим RUN |
|---|---|
| `go mod download` | `ENV GOPROXY=https://goproxy.io,direct` |
| `pip install` | `ENV PIP_DEFAULT_TIMEOUT=100 PIP_INDEX_URL=https://pypi.tuna.tsinghua.edu.cn/simple` |
| `pnpm install` + `lockfileVersion ... incompatible` | после `RUN corepack enable`: `RUN corepack prepare pnpm@8.15.9 --activate` |

Найти нужный Dockerfile: `grep -rl "go mod download" .` (подставь своё слово).

🎮 pnpm: сейв из старой версии игры не грузится в новую, поэтому запускаем старую версию.
💡 Всё равно не качается? Проверь VPN и Wi-Fi.
