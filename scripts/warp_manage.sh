#!/bin/bash
# scripts/warp_manage.sh
# Cloudflare WARP Management & DNS Optimization Settings
# Bilingual (CN / EN)

SCRIPT_PATH=$(dirname "$(readlink -f "$0")")
if [ -f "$SCRIPT_PATH/../lib/common.sh" ]; then
    . "$SCRIPT_PATH/../lib/common.sh"
elif [ -f "/tmp/vps-scripts/lib/common.sh" ]; then
    . "/tmp/vps-scripts/lib/common.sh"
fi

detect_language "$1"
require_root
install_pkgs curl wget

get_warp_msg() {
    local key="$1"
    case "$LANG_ENV" in
        CN)
            case "$key" in
                "title") echo "Cloudflare WARP 網際網路加速及 DNS 優化管理" ;;
                "opt_1") echo "安裝/升級 Cloudflare WARP 用戶端 (warp-cli)" ;;
                "opt_2") echo "開啟 WARP 全局代理隧道模式 (S4/v6 優先網關)" ;;
                "opt_3") echo "斷開 / 停止 WARP 網路代理鏈結" ;;
                "opt_4") echo "配置 WARP 單獨 SOCKS5 代理形式 (運行在 127.0.0.1:40000)" ;;
                "opt_5") echo "調優並重新設定本機 DNS 解析伺服器 (Auto DNS optimization)" ;;
                "status_is") echo "WARP 運作狀態: " ;;
                "not_inst") echo "未安裝" ;;
                "running") echo "連接成功" ;;
                "disconnected") echo "已中斷" ;;
            esac
            ;;
        *) # EN
            case "$key" in
                "title") echo "Cloudflare WARP Configuration & DNS Optimizations" ;;
                "opt_1") echo "Install/Upgrade Cloudflare WARP client tools" ;;
                "opt_2") echo "Enable WARP Global Tunnel (Prefer IPv4/v6 Gateway)" ;;
                "opt_3") echo "Disconnect & Suspend active WARP tunnel connections" ;;
                "opt_4") echo "Configure WARP local SOCKS5 proxy (Listening on 127.0.0.1:40000)" ;;
                "opt_5") echo "Run System DNS resolvers tuning automation scripts" ;;
                "status_is") echo "CF WARP Daemon running state: " ;;
                "not_inst") echo "Not installed" ;;
                "running") echo "Connected" ;;
                "disconnected") echo "Disconnected" ;;
            esac
            ;;
    esac
}

check_warp_status() {
    if ! command -v warp-cli &>/dev/null; then
        echo -e "$(get_warp_msg 'status_is') ${gl_hong}$(get_warp_msg 'not_inst')${gl_bai}"
    else
        local status=$(warp-cli status 2>/dev/null | grep -i "status" | awk '{print $NF}')
        if [[ "$status" == *"Connected"* ]]; then
            echo -e "$(get_warp_msg 'status_is') ${gl_lv}$(get_warp_msg 'running')${gl_bai}"
        else
            echo -e "$(get_warp_msg 'status_is') ${gl_huang}$(get_warp_msg 'disconnected')${gl_bai}"
        fi
    fi
}

install_warp() {
    if ! command -v warp-cli &>/dev/null; then
        echo -e "${gl_huang}Registering Cloudflare official package repository...${gl_bai}"
        local pm=$(detect_pm)
        case "$pm" in
            apt)
                curl -fsSL https://pkg.cloudflareclient.com/pubkey.gpg | gpg --dearmor -o /usr/share/keyrings/cloudflare-warp.gpg --yes
                local codename=$(. /etc/os-release && echo "$VERSION_CODENAME")
                echo "deb [signed-by=/usr/share/keyrings/cloudflare-warp.gpg] https://pkg.cloudflareclient.com/ $codename main" > /etc/apt/sources.list.d/cloudflare-client.list
                DEBIAN_FRONTEND=noninteractive apt-get update -y
                DEBIAN_FRONTEND=noninteractive apt-get install -y cloudflare-warp
                ;;
            dnf|yum)
                rpm -ivh https://pkg.cloudflareclient.com/cloudflare-release-el$(rpm -E %rhel).rpm 2>/dev/null
                yum install -y cloudflare-warp
                ;;
            *)
                echo "WARP installer only supports APT / YUM based systems."
                return 1
                ;;
        esac
        warp-cli registration new 2>/dev/null || warp-cli register 2>/dev/null
    fi
    echo "Cloudflare WARP client setup complete."
}

connect_warp() {
    if ! command -v warp-cli &>/dev/null; then
        return
    fi
    warp-cli mode warp 2>/dev/null
    warp-cli connect 2>/dev/null
    echo "Connecting to Cloudflare warp network..."
}

disconnect_warp() {
    if ! command -v warp-cli &>/dev/null; then
        return
    fi
    warp-cli disconnect 2>/dev/null
    echo "Warp disconnected."
}

socks5_warp() {
    if ! command -v warp-cli &>/dev/null; then
        return
    fi
    warp-cli mode proxy 2>/dev/null
    warp-cli proxy port 40000 2>/dev/null
    warp-cli connect 2>/dev/null
    echo "WARP client running in local SOCKS5 proxy mode: SOCKS5 address: 127.0.0.1:40000"
}

optimize_dns() {
    # Detect region, assign best public servers DNS resolvers settings
    local region=$(curl -s --max-time 2 ipinfo.io/country)
    if [[ "$region" == "CN" ]]; then
        cat <<EOF > /etc/resolv.conf
nameserver 223.5.5.5
nameserver 119.29.29.29
EOF
    else
        cat <<EOF > /etc/resolv.conf
nameserver 1.1.1.1
nameserver 8.8.8.8
EOF
    fi
    echo "DNS optimization scripts finished successfully."
}

warp_menu() {
    while true; do
        clear
        echo -e "${gl_kjlan}========================================================================${gl_bai}"
        echo -e "                 $(get_warp_msg 'title')                                "
        echo -e "${gl_kjlan}========================================================================${gl_bai}"
        check_warp_status
        echo -e "${gl_kjlan}------------------------------------------------------------------------${gl_bai}"
        echo -e "  ${gl_lv}1.${gl_bai} $(get_warp_msg 'opt_1')"
        echo -e "  ${gl_lv}2.${gl_bai} $(get_warp_msg 'opt_2')"
        echo -e "  ${gl_lv}3.${gl_bai} $(get_warp_msg 'opt_3')"
        echo -e "  ${gl_lv}4.${gl_bai} $(get_warp_msg 'opt_4')"
        echo -e "  ${gl_lv}5.${gl_bai} $(get_warp_msg 'opt_5')"
        echo -e "${gl_kjlan}------------------------------------------------------------------------${gl_bai}"
        echo -e "  ${gl_hong}0.${gl_bai} $(get_msg 'press_any_key')"
        echo -e "${gl_kjlan}========================================================================${gl_bai}"

        read -p "Selection: " sub_ch
        case "$sub_ch" in
            1) install_warp; break_end ;;
            2) connect_warp; break_end ;;
            3) disconnect_warp; break_end ;;
            4) socks5_warp; break_end ;;
            5) optimize_dns; break_end ;;
            0) return ;;
            *) echo -e "${gl_hong}$(get_msg 'invalid_selection')${gl_bai}"; sleep 2 ;;
        esac
    done
}

warp_menu
