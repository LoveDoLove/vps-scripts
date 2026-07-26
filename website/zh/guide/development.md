# 開發指南

## 架構規範

新增或修改腳本時，請遵循以下規範：

### 1. 務必載入 common.sh

```bash
# 每個 scripts/ 下的腳本開頭
SCRIPT_PATH=$(dirname "$(readlink -f "$0")")
. "$SCRIPT_PATH/../lib/common.sh"
```

這會提供：
- 顏色變數：`gl_lv`（綠）、`gl_huang`（黃）、`gl_hong`（紅）、`gl_kjlan`（青）等
- 套件管理器：`install_pkgs`、`remove_pkgs`
- 工具函式：`check_disk_space`、`check_swap`、`get_ip_address`、`check_port_taken`
- 翻譯：`get_msg "key"`

### 2. 雙語字串

所有使用者介面文字必須透過 `get_msg` 系統或模組層級的翻譯函式：

```bash
get_store_msg() {
    local key="$1"
    case "$LANG_ENV" in
        CN)
            case "$key" in
                "title") echo "Docker 軟體/應用市場一鍵安裝儲存庫" ;;
                "opt_1") echo "佈署 MySQL 資料庫服務" ;;
                ...
            esac
            ;;
        *)
            case "$key" in
                "title") echo "Docker App Store - Instant Deployment Launcher" ;;
                "opt_1") echo "Deploy MySQL Relational Database Server" ;;
                ...
            esac
            ;;
    esac
}
```

### 3. 跨發行版相容

- 腳本必須能在 Debian/Ubuntu（apt）、RHEL/Rocky/Alma/CentOS（dnf/yum）、
  Alpine（apk）、Arch（pacman）和 openSUSE（zypper）上運作。
- 使用共享的 `detect_pm` 函式 — 絕不硬編碼套件管理器命令。

### 4. Docker 應用市場規範

- 使用 `ensure_docker()` 自動安裝 Docker
- 綁定埠前使用 `check_port_taken()` 檢查衝突
- 建立新容器前先清理舊容器（`docker stop && docker rm`）

### 5. GitHub 代理

`lib/common.sh` 中的 `GH_PROXY` 變數優化中國大陸用戶的下載體驗。
載入遠端資源時請使用此設定。

## Pull Request 檢查清單

- [ ] 已載入 `lib/common.sh`
- [ ] 所有 UI 字串透過雙語 `get_msg` 機制
- [ ] 至少在 Debian/Ubuntu 和 Alpine 上測試
- [ ] Docker 埠有衝突檢測
- [ ] 無硬編碼的套件管理器命令
