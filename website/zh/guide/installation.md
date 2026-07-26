# 安裝方式

## 系統需求

- **Root 權限** — 大部分操作需要 root 權限
- **curl** 或 **wget** — 用於遠端載入模組
- **Docker**（選用）— 應用市場與 LDNMP 功能需要

## 方式一：遠端一鍵執行（推薦）

無需下載安裝，直接從 GitHub 執行：

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/LoveDoLove/vps-scripts/main/main.sh)
```

工具箱會自動偵測系統語言。若要強制指定語言：

```bash
# 強制英文
bash <(curl -fsSL https://raw.githubusercontent.com/LoveDoLove/vps-scripts/main/main.sh) en

# 強制中文
bash <(curl -fsSL https://raw.githubusercontent.com/LoveDoLove/vps-scripts/main/main.sh) cn
```

## 方式二：Clone 本地執行

```bash
git clone https://github.com/LoveDoLove/vps-scripts.git
cd vps-scripts
chmod +x main.sh scripts/*.sh lib/*.sh
bash main.sh
```

## 方式三：單一模組執行

`scripts/` 下的每個腳本都可獨立執行：

```bash
bash scripts/docker_manage.sh
bash scripts/app_store.sh
```

注意：腳本會從相對路徑載入 `lib/common.sh`。如果在專案目錄外執行，
會自動下載到 `/tmp/vps-scripts`。
