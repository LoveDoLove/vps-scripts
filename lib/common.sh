#!/bin/bash
# lib/common.sh
# Common utilities, colors, package managers, and bilingual translations
# Author: LoveDoLove/Claude 5

# Color definitions
gl_hui='\033[37m'
gl_hong='\033[31m'
gl_lv='\033[32m'
gl_huang='\033[33m'
gl_lan='\033[34m'
gl_zi='\033[35m'
gl_kjlan='\033[96m'
gl_bai='\033[0m'
gl_bold='\033[1m'

# Default parameters
LANG_ENV="EN"             # EN or CN
GITHUB_RAW_BASE="https://raw.githubusercontent.com/LoveDoLove/vps-scripts/main"
GH_PROXY="https://gh.kejilion.pro/"
ENABLE_STATS="false"      # Disable analytics by default for privacy, customizable.

# Detect client terminal language preference on run
detect_language() {
    # If the user passed "en" or "cn" as a command argument, enforce it
    if [[ "${1,,}" == "en" ]]; then
        LANG_ENV="EN"
    elif [[ "${1,,}" == "cn" ]]; then
        LANG_ENV="CN"
    else
        # Otherwise auto-detect from system environment
        if [[ "$LANG" == *"zh"* ]]; then
            LANG_ENV="CN"
        else
            LANG_ENV="EN"
        fi
    fi
}

# Simple translation helper
# Usage: get_msg "key"
get_msg() {
    local key="$1"
    case "$LANG_ENV" in
        CN)
            case "$key" in
                "press_any_key") echo "按任意鍵返回主選單..." ;;
                "press_to_continue") echo "按任意鍵繼續..." ;;
                "operation_success") echo "操作完成。" ;;
                "invalid_selection") echo "無效的選擇！請輸入有效的選項。" ;;
                "need_root") echo "此操作需要 root 權限，請切換至 root 或使用 sudo 執行。" ;;
                "detecting_os") echo "正在偵測操作系統..." ;;
                "unknown_pm") echo "未知的套件管理器！" ;;
                "disk_insufficient") echo "磁碟空間不足！" ;;
                "current_avail") echo "當前可用空間: " ;;
                "min_req") echo "最小需求空間: " ;;
                "cannot_continue") echo "無法繼續，請清理磁碟空間後重試。" ;;
                "installing") echo "正在安裝 " ;;
                "uninstalling") echo "正在卸載 " ;;
                "install_success") echo "安裝成功。" ;;
                "install_failed") echo "安裝失敗。" ;;
                "agreement_title") echo "歡迎使用 VPS Scripts 運維工具箱" ;;
                "agreement_desc") echo "首次使用，請先同意用戶使用條款及協議。" ;;
                "agreement_ask") echo "是否同意以上條款？(y/n): " ;;
                "checking_swap") echo "正在檢查虛擬記憶體(swap)..." ;;
                "creating_swap") echo "正在建立虛擬記憶體..." ;;
                "swap_adjusted") echo "虛擬記憶體大小已調整為: " ;;
                "switching_ipv4_pref") echo "已切換為 IPv4 優先。" ;;
                *) echo "$key" ;;
            esac
            ;;
        *) # Default (EN)
            case "$key" in
                "press_any_key") echo "Press any key to return to main menu..." ;;
                "press_to_continue") echo "Press any key to continue..." ;;
                "operation_success") echo "Operation completed successfully." ;;
                "invalid_selection") echo "Invalid selection! Please enter a valid option." ;;
                "need_root") echo "This operation requires root privileges. Please run as root or with sudo." ;;
                "detecting_os") echo "Detecting operating system..." ;;
                "unknown_pm") echo "Unknown package manager!" ;;
                "disk_insufficient") echo "Disk space is insufficient!" ;;
                "current_avail") echo "Current available space: " ;;
                "min_req") echo "Minimum required space: " ;;
                "cannot_continue") echo "Cannot proceed, please clean up disk space first." ;;
                "installing") echo "Installing " ;;
                "uninstalling") echo "Uninstalling " ;;
                "install_success") echo "Installed successfully." ;;
                "install_failed") echo "Failed to install." ;;
                "agreement_title") echo "Welcome to VPS Scripts Management Toolkit" ;;
                "agreement_desc") echo "Please read and agree to user terms and services before first run." ;;
                "agreement_ask") echo "Do you agree to the terms? (y/n): " ;;
                "checking_swap") echo "Checking Virtual Memory (Swap)..." ;;
                "creating_swap") echo "Creating Swap file..." ;;
                "swap_adjusted") echo "Swap space adjusted to: " ;;
                "switching_ipv4_pref") echo "Switched to prefer IPv4 DNS resolution." ;;
                *) echo "$key" ;;
            esac
            ;;
    esac
}

# Require root user
require_root() {
    if [ "$EUID" -ne 0 ]; then
        echo -e "${gl_hong}$(get_msg 'need_root')${gl_bai}"
        exit 1
    fi
}

# Detect package managers
detect_pm() {
    if command -v dnf &>/dev/null; then
        echo "dnf"
    elif command -v yum &>/dev/null; then
        echo "yum"
    elif command -v apt-get &>/dev/null; then
        echo "apt"
    elif command -v apk &>/dev/null; then
        echo "apk"
    elif command -v pacman &>/dev/null; then
        echo "pacman"
    elif command -v zypper &>/dev/null; then
        echo "zypper"
    elif command -v opkg &>/dev/null; then
        echo "opkg"
    elif command -v pkg &>/dev/null; then
        echo "pkg"
    else
        echo "unknown"
    fi
}

# Install dependencies (apt, dnf, apk, etc.)
install_pkgs() {
    if [ $# -eq 0 ]; then
        return 1
    fi

    local pm=$(detect_pm)
    for pkg in "$@"; do
        if ! command -v "$pkg" &>/dev/null; then
            echo -e "${gl_kjlan}$(get_msg 'installing') $pkg...${gl_bai}"
            case "$pm" in
                apt)
                    DEBIAN_FRONTEND=noninteractive apt-get update -y >/dev/null 2>&1
                    DEBIAN_FRONTEND=noninteractive apt-get install -y "$pkg"
                    ;;
                dnf)
                    dnf makecache >/dev/null 2>&1
                    dnf install -y "$pkg"
                    ;;
                yum)
                    yum makecache >/dev/null 2>&1
                    yum install -y "$pkg"
                    ;;
                apk)
                    apk update >/dev/null 2>&1
                    apk add "$pkg"
                    ;;
                pacman)
                    pacman -Sy --noconfirm >/dev/null 2>&1
                    pacman -S --noconfirm "$pkg"
                    ;;
                zypper)
                    zypper refresh >/dev/null 2>&1
                    zypper install -y "$pkg"
                    ;;
                opkg)
                    opkg update >/dev/null 2>&1
                    opkg install "$pkg"
                    ;;
                pkg)
                    pkg update >/dev/null 2>&1
                    pkg install -y "$pkg"
                    ;;
                *)
                    echo -e "${gl_hong}$(get_msg 'unknown_pm')${gl_bai}"
                    return 1
                    ;;
            esac

            if command -v "$pkg" &>/dev/null; then
                echo -e "${gl_lv}$pkg $(get_msg 'install_success')${gl_bai}"
            else
                echo -e "${gl_hong}$pkg $(get_msg 'install_failed')${gl_bai}"
            fi
        fi
    done
}

# Uninstall dependencies
remove_pkgs() {
    if [ $# -eq 0 ]; then
        return 1
    fi

    local pm=$(detect_pm)
    for pkg in "$@"; do
        echo -e "${gl_kjlan}$(get_msg 'uninstalling') $pkg...${gl_bai}"
        case "$pm" in
            apt)
                DEBIAN_FRONTEND=noninteractive apt-get purge -y "$pkg"
                DEBIAN_FRONTEND=noninteractive apt-get autoremove -y
                ;;
            dnf)
                dnf remove -y "$pkg"
                ;;
            yum)
                yum remove -y "$pkg"
                ;;
            apk)
                apk del "$pkg"
                ;;
            pacman)
                pacman -Rns --noconfirm "$pkg"
                ;;
            zypper)
                zypper remove -y "$pkg"
                ;;
            opkg)
                opkg remove "$pkg"
                ;;
            pkg)
                pkg delete -y "$pkg"
                ;;
            *)
                echo -e "${gl_hong}$(get_msg 'unknown_pm')${gl_bai}"
                return 1
                ;;
        esac
    done
}

# Check disk space
check_disk_space() {
    local req_gb=$1
    local dest_path=${2:-/}

    mkdir -p "$dest_path" 2>/dev/null
    local req_mb=$((req_gb * 1024))
    local avail_mb=$(df -m "$dest_path" | awk 'NR==2 {print $4}')

    if [ "$avail_mb" -lt "$req_mb" ]; then
        echo -e "${gl_hong}$(get_msg 'disk_insufficient')${gl_bai}"
        echo "$(get_msg 'current_avail'): $((avail_mb/1024))G"
        echo "$(get_msg 'min_req'): ${req_gb}G"
        echo -e "${gl_huang}$(get_msg 'cannot_continue')${gl_bai}"
        break_end
        exit 1
    fi
}

# Check swap size and optimize
check_swap() {
    echo -e "${gl_kjlan}$(get_msg 'checking_swap')${gl_bai}"
    local swap_total=$(free -m | awk 'NR==3{print $2}')
    if [ "$swap_total" -eq 0 ]; then
        add_swap 1024
    fi
}

# Adjust swap file length
add_swap() {
    local size_mb=$1
    echo -e "${gl_huang}$(get_msg 'creating_swap') (${size_mb}M)...${gl_bai}"

    # Turn off existing swap in file
    swapoff /swapfile 2>/dev/null
    rm -f /swapfile

    fallocate -l ${size_mb}M /swapfile
    chmod 600 /swapfile
    mkswap /swapfile
    swapon /swapfile

    sed -i '/\/swapfile/d' /etc/fstab
    echo "/swapfile swap swap defaults 0 0" >> /etc/fstab

    # Alpine specific swap hook
    if [ -f /etc/alpine-release ]; then
        echo "nohup swapon /swapfile" > /etc/local.d/swap.start
        chmod +x /etc/local.d/swap.start
        rc-update add local
    fi

    echo -e "$(get_msg 'swap_adjusted') ${gl_huang}${size_mb}${gl_bai}M"
}

# Prefer IPv4 DNS Gai.conf
prefer_ipv4() {
    grep -q '^precedence ::ffff:0:0/96  100' /etc/gai.conf 2>/dev/null \
        || echo 'precedence ::ffff:0:0/96  100' >> /etc/gai.conf
    echo -e "${gl_lv}$(get_msg 'switching_ipv4_pref')${gl_bai}"
}

# Get public and local networks
get_ip_address() {
    local_ipv4=$(ip route get 8.8.8.8 2>/dev/null | grep -oP 'src \K[^ ]+' || \
                 hostname -I 2>/dev/null | awk '{print $1}')
    public_ipv4=$(curl -s --connect-timeout 3 --max-time 5 https://ipinfo.io/ip 2>/dev/null)
    public_ipv6=$(curl -s --connect-timeout 2 --max-time 3 https://v6.ipinfo.io/ip 2>/dev/null)
}

# Verify if a port is already taken/in use locally
check_port_taken() {
    local port="$1"
    if command -v ss &>/dev/null; then
        ss -tuln | grep -q ":$port "
    elif command -v netstat &>/dev/null; then
        netstat -tuln | grep -q ":$port "
    else
        # Fallback raw bash sockets checker
        (echo > /dev/tcp/127.0.0.1/"$port") &>/dev/null
    fi
}

# User license agreement flow
user_agreement() {
    # Check if user already permitted terms earlier
    if [[ ! -f ~/.vps_scripts_agreed ]]; then
        clear
        echo -e "${gl_kjlan}====================================================${gl_bai}"
        echo -e "         $(get_msg 'agreement_title')               "
        echo -e "  $(get_msg 'agreement_desc')                       "
        echo -e "${gl_kjlan}====================================================${gl_bai}"
        read -e -p "$(get_msg 'agreement_ask')" user_input
        if [[ "$user_input" == "y" || "$user_input" == "Y" ]]; then
            touch ~/.vps_scripts_agreed
        else
            echo "Terms rejected. Exiting."
            exit 1
        fi
    fi
}

# Clean terminal loop breaks
break_end() {
    echo ""
    echo -e "${gl_lv}$(get_msg 'operation_success')${gl_bai}"
    echo -e "${gl_huang}$(get_msg 'press_to_continue')${gl_bai}"
    read -n 1 -s -r -p ""
    echo ""
}

# Simple wrapper for systemctl that is compatible with openrc(Alpine)
sys_service() {
    local command="$1"
    local service="$2"
    if command -v apk &>/dev/null; then
        service "$service" "$command"
    else
        systemctl "$command" "$service"
    fi
}
