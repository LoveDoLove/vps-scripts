# 核心升級與 BBR 加速

主選單選項 **3**。

## 功能

- **TCP BBR** — 啟用 Google 的 BBR 壅塞控制演算法
- **XanMod 核心** — 安裝高效能第三方核心，支援 BBRv3
- **ELRepo 核心** — 透過 ELRepo 升級至最新主線核心（RHEL 系列）
- **佇列演算法** — 設定 `fq` 或 `fq_codel` 為預設 qdisc

## 腳本

`scripts/kernel_manage.sh`
