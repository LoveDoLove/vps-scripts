---
layout: home

hero:
  name: "VPS Scripts"
  text: "模組化 VPS 伺服器管理工具箱"
  tagline: 一鍵伺服器運維 — 系統工具、防火牆、SSL、Docker、核心調校，全面支援中英雙語
  image:
    src: /logo.png
    alt: VPS Scripts Logo
  actions:
    - theme: brand
      text: 快速開始
      link: /zh/guide/
    - theme: alt
      text: 在 GitHub 上檢視
      link: https://github.com/LoveDoLove/vps-scripts
    - theme: brand
      text: 立即執行 →
      link: /zh/guide/installation#遠端一鍵執行

features:
  - icon: 🧩
    title: 模組化架構
    details: 每個功能獨立為 scripts/ 下的腳本，由 main.sh 主選單按需載入。
  - icon: 🌐
    title: 雙語支援
    details: 自動偵測系統語言，完整呈現英文或繁體中文選單與訊息。
  - icon: ⚡
    title: 一鍵執行
    details: 無需下載，直接從 GitHub 遠端執行 bash &lt;(curl -fsSL ...)。
  - icon: 🐳
    title: Docker 應用市場
    details: 一鍵佈署 MySQL、Redis、WordPress、NPM、Portainer 等，內建端口衝突檢測。
  - icon: 🖥️
    title: 跨發行版相容
    details: 已在 Debian、Ubuntu、RHEL、Rocky、Alma、CentOS、Alpine、Arch 等驗證。
  - icon: 🔒
    title: 安全優先
    details: 內建防火牆管理、WAF、DDoS 防護、GeoIP 封鎖（ipset）與 SSL 自動續簽。
---

## 快速安裝

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/LoveDoLove/vps-scripts/main/main.sh)
```

輸入數字選擇功能模組，即可開始使用。
