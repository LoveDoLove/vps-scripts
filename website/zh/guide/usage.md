# 使用說明

啟動後顯示互動式數字選單。輸入功能編號按 Enter 即可。

## 主選單

```
========================================================================
               LoveDoLove VPS Management Toolkit
               Version: 1.0.0 | Language: CN
========================================================================
 本機 IPv4: 10.0.0.1 | 公網 IPv4: 1.2.3.4
 公網 IPv6: 2001:db8::1
 系統資訊:  Linux 6.8.0 x86_64
------------------------------------------------------------------------
  1. 系統更新與基礎工具 (Update & Basic Tools)
  2. 防火牆與高級安全管理 (Firewall & WAF Security)
  3. 核心升級與 BBR 加速 (Kernel & BBR Acceleration)
  4. SSL 憑證管理 (SSL Certificate Manager)
  5. LDNMP 建站管理面板 (LDNMP Web Stack Docker)
  6. Docker 環境與容器管理 (Docker & Containers)
  7. Docker 軟體/應用市場 (Docker Application Store)
  8. FRP 內網穿透與監控告警 (FRP Proxy & Prometheus)
  9. 系統清理、備份與定時任務 (Backup, Cleanup & Cron)
  10. 服務器網絡測試與性能 Bench (Network tests & Benchmarks)
  11. 網絡輔助與優化工具 (DNS, WARP, Routing Preferences)
  12. 物理/雲服務器一鍵 DD 重裝 (Server OS Reinstallation DD)
  13. 甲骨文雲專屬組態優化工具 (Oracle Cloud Instance Specifics)
------------------------------------------------------------------------
  0. 退出腳本 (Exit)
========================================================================
```

## 模組操作

選擇功能後，對應的 `scripts/<module_name>.sh` 會被載入並顯示該模組的子選單。
例如選擇 **7（應用市場）** 會顯示：

```
========================================================================
          Docker 軟體/應用市場一鍵安裝儲存庫
========================================================================
  1. 佈署 MySQL 資料庫服務
  2. 佈署 Redis 快取服務
  3. 佈署 phpMyAdmin 資料庫網頁端
  4. 佈署 Nginx Proxy Manager 代理面板
  5. 佈署 Portainer 容器可視化管理端
  6. 佈署 1Panel 新一代 Linux 運維面板
  7. 佈署 Node.js / Python 容器端環境
  8. 佈署 WordPress (包含 MySQL 完整容器棧)
  9. 佈署 PostgreSql + pgAdmin 資料庫集成環境
  10. 佈署 Nginx 靜態 Web 網頁伺服器
  11. 佈署 Vaultwarden (Bitwarden 密碼管理器)
------------------------------------------------------------------------
  0. 返回主選單
========================================================================
```

## 操作提示

- **0** 總是返回上一層選單（或退出程式）
- 模組按需載入 — 啟動時只執行 `main.sh`
- 語言自動偵測使用 `$LANG` — 可用 `bash main.sh cn` 強制指定
