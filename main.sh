#!/bin/bash
# main.sh
# Main menu entrypoint for LoveDoLove VPS Toolkit
# Bilingual Support (CN / EN)

# Define GitHub raw repo address for remote scripts loading
# Target script path
SCRIPT_PATH=$(dirname "$(readlink -f "$0")")

# Fallback base URL for remote execute (curl/wget download run)
GITHUB_RAW_BASE="https://raw.githubusercontent.com/LoveDoLove/vps-scripts/main/scripts"

# Load local lib if exists, else pull remotely
if [ -f "$SCRIPT_PATH/lib/common.sh" ]; then
    . "$SCRIPT_PATH/lib/common.sh"
else
    # Remote fallback download logic
    mkdir -p /tmp/vps-scripts/lib 2>/dev/null
    curl -sSL "https://raw.githubusercontent.com/LoveDoLove/vps-scripts/main/lib/common.sh" -o /tmp/vps-scripts/lib/common.sh
    . /tmp/vps-scripts/lib/common.sh
fi

# Multi-platform language detector
detect_language "$1"
user_agreement

# Menu builder
main_menu() {
    clear
    get_ip_address
    echo -e "${gl_kjlan}========================================================================${gl_bai}"
    echo -e "${gl_bold}               LoveDoLove VPS Management Toolkit                      ${gl_bai}"
    echo -e "               Version: 1.0.0 | Language: $LANG_ENV                    "
    echo -e "${gl_kjlan}========================================================================${gl_bai}"

    if [[ "$LANG_ENV" == "CN" ]]; then
        echo -e " 本機 IPv4: ${gl_huang}${local_ipv4:-未偵測}${gl_bai} | 公網 IPv4: ${gl_huang}${public_ipv4:-無}${gl_bai}"
        echo -e " 公網 IPv6: ${gl_huang}${public_ipv6:-無}${gl_bai}"
        echo -e " 系統資訊:  $(uname -s -r -m)"
        echo -e "${gl_kjlan}------------------------------------------------------------------------${gl_bai}"
        echo -e "  ${gl_lv}1.${gl_bai} 系統更新與基礎工具 (Update & Basic Tools)"
        echo -e "  ${gl_lv}2.${gl_bai} 防火牆與高級安全管理 (Firewall & WAF Security)"
        echo -e "  ${gl_lv}3.${gl_bai} 核心升級與 BBR 加速 (Kernel & BBR Acceleration)"
        echo -e "  ${gl_lv}4.${gl_bai} SSL 憑證管理 (SSL Certificate Manager)"
        echo -e "  ${gl_lv}5.${gl_bai} LDNMP 建站管理面板 (LDNMP Web Stack Docker)"
        echo -e "  ${gl_lv}6.${gl_bai} Docker 環境與容器管理 (Docker & Containers)"
        echo -e "  ${gl_lv}7.${gl_bai} Docker 軟體/應用市場 (Docker Application Store)"
        echo -e "  ${gl_lv}8.${gl_bai} FRP 內網穿透與監控告警 (FRP Proxy & Prometheus)"
        echo -e "  ${gl_lv}9.${gl_bai} 系統清理、備份與定時任務 (Backup, Cleanup & Cron)"
        echo -e "  ${gl_lv}10.${gl_bai} 服務器網絡測試與性能 Bench (Network tests & Benchmarks)"
        echo -e "  ${gl_lv}11.${gl_bai} 網絡輔助與優化工具 (DNS, WARP, Routing Preferences)"
        echo -e "  ${gl_lv}12.${gl_bai} 物理/雲服務器一鍵 DD 重裝 (Server OS Reinstallation DD)"
        echo -e "  ${gl_lv}13.${gl_bai} 甲骨文雲專屬組態優化工具 (Oracle Cloud Instance Specifics)"
        echo -e "${gl_kjlan}------------------------------------------------------------------------${gl_bai}"
        echo -e "  ${gl_hong}0.${gl_bai} 退出腳本 (Exit)"
        echo -e "${gl_kjlan}========================================================================${gl_bai}"
    else
        echo -e " Local IPv4: ${gl_huang}${local_ipv4:-N/A}${gl_bai} | Public IPv4: ${gl_huang}${public_ipv4:-N/A}${gl_bai}"
        echo -e " Public IPv6: ${gl_huang}${public_ipv6:-N/A}${gl_bai}"
        echo -e " OS Info:    $(uname -s -r -m)"
        echo -e "${gl_kjlan}------------------------------------------------------------------------${gl_bai}"
        echo -e "  ${gl_lv}1.${gl_bai} System Update & Basic Tools"
        echo -e "  ${gl_lv}2.${gl_bai} Firewall & WAF Security"
        echo -e "  ${gl_lv}3.${gl_bai} Kernel & BBR Tuning"
        echo -e "  ${gl_lv}4.${gl_bai} SSL Certificate Management"
        echo -e "  ${gl_lv}5.${gl_bai} LDNMP Web Stack Docker Control"
        echo -e "  ${gl_lv}6.${gl_bai} Docker & Container Management"
        echo -e "  ${gl_lv}7.${gl_bai} Docker App Store (Applications)"
        echo -e "  ${gl_lv}8.${gl_bai} FRP Tunneling & Monitoring (Grafana/Prometheus)"
        echo -e "  ${gl_lv}9.${gl_bai} System Cleanup, Backups & Cronjobs"
        echo -e "  ${gl_lv}10.${gl_bai} Network Speedtests & Benchmarks"
        echo -e "  ${gl_lv}11.${gl_bai} DNS Optimization & Cloudflare WARP tools"
        echo -e "  ${gl_lv}12.${gl_bai} Cloud OS Direct DD Reinstallation"
        echo -e "  ${gl_lv}13.${gl_bai} Oracle Cloud Instance Specific Optimizations"
        echo -e "${gl_kjlan}------------------------------------------------------------------------${gl_bai}"
        echo -e "  ${gl_hong}0.${gl_bai} Quit Toolkit"
        echo -e "${gl_kjlan}========================================================================${gl_bai}"
    fi
}

load_module() {
    local module_name="$1"
    local local_file="$SCRIPT_PATH/scripts/${module_name}.sh"

    if [ -f "$local_file" ]; then
        bash "$local_file" "$LANG_ENV"
    else
        echo -e "${gl_huang}Downloading module ${module_name} remotely...${gl_bai}"
        mkdir -p /tmp/vps-scripts/scripts 2>/dev/null
        curl -sSL "${GITHUB_RAW_BASE}/${module_name}.sh" -o "/tmp/vps-scripts/scripts/${module_name}.sh"
        bash "/tmp/vps-scripts/scripts/${module_name}.sh" "$LANG_ENV"
    fi
}

# Process options
handle_choice() {
    case "$1" in
        1) load_module "system_tools" ;;
        2) load_module "firewall_manage" ;;
        3) load_module "kernel_manage" ;;
        4) load_module "ssl_manage" ;;
        5) load_module "web_manage" ;;
        6) load_module "docker_manage" ;;
        7) load_module "app_store" ;;
        8) load_module "frp_manage" ;;
        9) load_module "backup_manage" ;;
        10) load_module "test_scripts" ;;
        11) load_module "warp_manage" ;;
        12) load_module "dd_system" ;;
        13) load_module "oracle_cloud" ;;
        0) clear; exit 0 ;;
        *) echo -e "${gl_hong}$(get_msg 'invalid_selection')${gl_bai}"; sleep 2 ;;
    esac
}

# Main Loop
while true; do
    main_menu
    if [[ "$LANG_ENV" == "CN" ]]; then
        read -p "請輸入您的選擇 [0-13]: " choice
    else
        read -p "Please enter your choice [0-13]: " choice
    fi
    handle_choice "$choice"
done
