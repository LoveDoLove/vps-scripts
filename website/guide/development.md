# Development

## Architecture Rules

When adding or modifying scripts, follow these conventions:

### 1. Always source common.sh

```bash
# At the top of every script in scripts/
SCRIPT_PATH=$(dirname "$(readlink -f "$0")")
. "$SCRIPT_PATH/../lib/common.sh"
```

This gives you access to:
- Color variables: `gl_lv` (green), `gl_huang` (yellow), `gl_hong` (red), `gl_kjlan` (cyan), etc.
- Package manager via `install_pkgs` and `remove_pkgs`
- Utilities: `check_disk_space`, `check_swap`, `get_ip_address`, `check_port_taken`
- Translation via `get_msg "key"`

### 2. Bilingual strings

All user-facing text must go through the `get_msg` system (in `lib/common.sh`)
or a module-level translation function:

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

### 3. Portability

- Scripts must work on Debian/Ubuntu (apt), RHEL/Rocky/Alma/CentOS (dnf/yum),
  Alpine (apk), Arch (pacman), and openSUSE (zypper).
- Use the shared `detect_pm` function — never hardcode a package manager.

### 4. Docker App Store guidelines

- Use `ensure_docker()` to auto-install Docker if missing.
- Use `check_port_taken()` before binding ports.
- Clean up old containers (`docker stop && docker rm`) before creating new ones.

### 5. GitHub Proxy

The `GH_PROXY` variable in `lib/common.sh` (`https://gh.kejilion.pro/`) optimizes
downloads for users in mainland China. Respect it when fetching remote resources.

## Pull Request Checklist

- [ ] Sources `lib/common.sh`
- [ ] All UI strings are bilingual via `get_msg`
- [ ] Tested on at least Debian/Ubuntu and Alpine
- [ ] Port collision check for Docker ports
- [ ] No hardcoded package manager commands
