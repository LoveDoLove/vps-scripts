# 介紹

VPS Scripts 是一套全面且模組化的 VPS 運維工具箱。原始的高耦合單體腳本已完整重構為模組化架構，並完美支援中英雙語。

## 設計理念

- **專注單一職責** — 每個腳本處理一個領域
- **隨處可執行** — 一鍵遠端執行，無需安裝
- **說你的語言** — 完整雙語界面，自動偵測系統語言
- **Docker 優先** — 應用市場與網站棧基於容器，內建端口安全檢測

## 架構

```
vps-scripts/
├── main.sh          # 互動式主選單入口
├── lib/
│   └── common.sh    # 顏色、套件管理器、翻譯、工具函式
├── scripts/
│   ├── system_tools.sh
│   ├── firewall_manage.sh
│   ├── kernel_manage.sh
│   ├── ssl_manage.sh
│   ├── web_manage.sh
│   ├── docker_manage.sh
│   ├── app_store.sh     # 11 種一鍵 Docker 佈署
│   ├── frp_manage.sh
│   ├── backup_manage.sh
│   ├── test_scripts.sh
│   ├── warp_manage.sh
│   ├── dd_system.sh
│   ├── oracle_cloud.sh
│   └── system_info.sh   # 系統資訊面板
└── images/
    └── logo.png
```
