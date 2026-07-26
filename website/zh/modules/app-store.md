# Docker 應用市場

主選單選項 **7**。一鍵佈署熱門 Docker 應用，自動檢測連接埠衝突。

## 可用應用

| # | 應用 | 預設埠 | 說明 |
|---|------|--------|------|
| 1 | **MySQL** | 3306 | 關聯式資料庫，可自訂 root 密碼 |
| 2 | **Redis** | 6379 | 記憶體快取伺服器，可選密碼保護 |
| 3 | **phpMyAdmin** | 8080 | 網頁版 MySQL/MariaDB 管理介面 |
| 4 | **Nginx Proxy Manager** | 80/81/443 | 網頁版 Nginx 反向代理管理 |
| 5 | **Portainer** | 8000/9443 | Docker 容器可視化管理 |
| 6 | **1Panel** | — | 新一代 Linux 運維面板（官方安裝腳本） |
| 7 | **Node.js / Python 沙盒** | — | CLI 工作環境容器（不暴露埠） |
| 8 | **WordPress 完整棧** | 8000 | WordPress + MySQL 透過 Docker Compose |
| 9 | **PostgreSQL + pgAdmin** | 5432/5050 | Postgres 資料庫 + pgAdmin 網頁主控台 |
| 10 | **獨立 Nginx** | 8081 | 輕量靜態網頁伺服器 |
| 11 | **Vaultwarden** | 8088 | 自架 Bitwarden 相容密碼管理器 |

## 主要特色

- **埠衝突檢測** — `check_port_taken()` 綁定前確認埠未被佔用
- **自動安裝 Docker** — `ensure_docker()` 在需要時自動安裝
- **隨機密碼** — 未指定時自動產生安全密碼
- **重新啟動政策** — 所有容器使用 `--restart always`

## 腳本

`scripts/app_store.sh`
