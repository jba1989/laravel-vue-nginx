# Laravel Vue Nginx 開發與 Log 收集說明

此專案使用 `docker compose` 啟動本地開發環境，包含 Laravel、Nuxt、Nginx、MySQL、Redis，以及用來收集 container log 的 `Alloy`。

## 服務說明

- `php`：Laravel 應用程式主服務
- `reverb`：Laravel Reverb / WebSocket 相關服務
- `node`：Nuxt 前端開發服務
- `nginx`：反向代理入口
- `mysql`：MySQL 資料庫
- `redis`：Redis 快取
- `alloy`：收集 Docker container logs，轉送到 Zeabur 上的 VictoriaLogs

## 環境變數

請先設定根目錄的 `.env`：

```env
MYSQL_DATABASE=stock
MYSQL_USER=laravel
MYSQL_PASSWORD=123456
MYSQL_ROOT_PASSWORD=654321

REDIS_PASSWORD=rreeddiiss

HOST=stock.local

VLOGS_PUSH_URL=https://<你的-victorialogs-公開網域>/insert/loki/api/v1/push
VLOGS_USERNAME=<basic-auth-帳號>
VLOGS_PASSWORD=<basic-auth-密碼>
LOG_HOSTNAME=<這台 Docker 主機的識別名稱>
```

說明：

- `VLOGS_PUSH_URL` 必須指向 Zeabur 官方模板建立的 `VictoriaLogs` 公開網域
- `VLOGS_USERNAME`、`VLOGS_PASSWORD` 要和 VictoriaLogs 對外保護設定一致
- `LOG_HOSTNAME` 只是 log label，用來區分來源主機，例如 `macbook-dev`、`home-server-1`

## 啟動方式

啟動全部服務：

```bash
docker compose up -d
```

依服務啟動：

```bash
docker compose up -d php
docker compose up -d reverb
docker compose up -d node
docker compose up -d nginx
docker compose up -d mysql
docker compose up -d redis
docker compose up -d alloy
```

查看個別服務 log：

```bash
docker compose logs -f php
docker compose logs -f reverb
docker compose logs -f node
docker compose logs -f nginx
docker compose logs -f mysql
docker compose logs -f redis
docker compose logs -f alloy
```

停止個別服務：

```bash
docker compose stop php
docker compose stop reverb
docker compose stop node
docker compose stop nginx
docker compose stop mysql
docker compose stop redis
docker compose stop alloy
```

## Alloy Log 收集

`docker-compose.yml` 內的 `alloy` 服務會：

- 從 `/var/run/docker.sock` 讀取所有 container 的 `stdout/stderr`
- 從 `mysql-slowlog` volume 讀取 MySQL slow query log 檔案
- 自動加上 `job`、`host`、`compose_project`、`service`、`container`、`image` 等 label
- 將 log 傳送到 `VLOGS_PUSH_URL`
- 排除 `alloy` 自己的 container log

### Log Level 統一格式

所有服務的 `level` label 統一輸出為 Title Case：

| Level | 對應服務 |
|-------|----------|
| `Debug` | nginx, laravel, node |
| `Info` | nginx, laravel, node |
| `Notice` | nginx |
| `Warning` | nginx, laravel, node, traefik, mysql, mysql slow query |
| `Error` | nginx, laravel, node, traefik, mysql |
| `Critical` | nginx, laravel |
| `Alert` | nginx, laravel, mysql |
| `Emergency` | nginx, laravel |
| `Fatal` | node, traefik |
| `Trace` | traefik |
| `Note` | mysql |
| `System` | mysql |

### 各服務保留等級

| 服務 | 保留等級 |
|------|----------|
| `nginx` access log | Error 以上（4xx / 5xx） |
| `nginx` error log | Warning 以上 |
| `php` / `reverb` | Info 以上（Debug 丟棄） |
| `node` | 全部保留（有 level 的行） |
| `traefik` | Warning 以上 |
| `mysql` | Warning 以上（Note、System 也保留） |
| `mysql` slow query | 全部保留（超過 `long_query_time` 才會寫入） |
| 其他服務 | Warning 以上 |

### MySQL Slow Query Log

`my.cnf` 設定：

- `long_query_time = 1`：執行超過 1 秒的查詢才記錄
- slow log 寫到容器內的 `/var/log/mysql/slow.log`，透過 `mysql-slowlog` named volume 讓 Alloy 直接讀取

每筆 slow query 記錄為多行，Alloy 以 `# Time:` 作為分隔合併後一起送出。在 VictoriaLogs 查詢時使用：

```text
{service="mysql", log_type="slow_query"}
```

### 為什麼需要 `alloy-data:/var/lib/alloy/data`

這個 volume 用來保存 Alloy 的本地狀態，不是拿來長期保存應用程式 log。

它的用途是：

- 記住 Docker logs 已經讀到哪裡（包含 slow log 檔案的讀取位置）
- 避免 Alloy 重啟或 container 重建後，重新讀取與重送大量舊 log
- 在短暫中斷後，讓 collector 可以延續既有 checkpoint

真正的 log 儲存位置仍然是在 Zeabur 上的 `VictoriaLogs`。

## Zeabur VictoriaLogs 對接

若使用 Zeabur 官方模板建立 `VictoriaLogs`，請確認：

- 該服務已綁定公開網域
- 本機 `.env` 的 `VLOGS_PUSH_URL` 使用：

```env
VLOGS_PUSH_URL=https://<公開網域>/insert/loki/api/v1/push
```

注意：

- 不要自行加上 `:9428` 對外連線
- `9428` 是服務內部 port，Zeabur 對外通常走公開網域的 HTTPS 入口

## 驗證方式

確認 `alloy` 正常啟動：

```bash
docker compose up -d alloy
docker compose logs -f alloy
```

確認本機某個服務有輸出 warning：

```bash
docker compose logs --tail=20 php
```

直接查詢 VictoriaLogs：

```bash
curl -sk -u "<帳號>:<密碼>" \
  "https://<公開網域>/select/logsql/query" \
  --data-urlencode 'query=service:"php"' \
  --data-urlencode 'limit=10'
```

也可以用 Grafana Explore 查詢：

```text
service:"php"
service:"node"
service:"mysql" AND log_type:"slow_query"
compose_project:"laravel-vue-nginx"
```
