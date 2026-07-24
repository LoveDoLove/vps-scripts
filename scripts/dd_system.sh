#!/bin/bash
# scripts/dd_system.sh
# One-click Server Direct DD Reinstallation Utilities
# Bilingual (CN / EN)

SCRIPT_PATH=$(dirname "$(readlink -f "$0")")
if [ -f "$SCRIPT_PATH/../lib/common.sh" ]; then
    . "$SCRIPT_PATH/../lib/common.sh"
elif [ -f "/tmp/vps-scripts/lib/common.sh" ]; then
    . "/tmp/vps-scripts/lib/common.sh"
fi

detect_language "$1"
require_root
install_pkgs curl wget tar

get_dd_msg() {
    local key="$1"
    case "$LANG_ENV" in
        CN)
            case "$key" in
                "title") echo "物理/雲端服務器 OS 磁碟鏡像 DD 一鍵重裝系統" ;;
                "warn") echo "【重要警告】DD 磁碟重新安裝具有可能失聯的系統風險。請務必完整備份資料！" ;;
                "opt_1") echo "重裝為 Debian 12 (LeitboGi0ro 腳本)" ;;
                "opt_2") echo "重裝為 Ubuntu 22.04 (LeitboGi0ro 腳本)" ;;
                "opt_3") echo "重裝為 Alpine Linux 微型極簡發行版" ;;
                "opt_4") echo "重裝為 Rocky Linux 9" ;;
                "start_dd") echo "正在為您架設引導並下載重裝程式，完成後會主動重啟..." ;;
                "creds_tip") echo "重裝預設登入密碼: LeitboGi0ro \n注意: 重啟配置約需要 5-15 分鐘，請耐心等待網絡重聯。" ;;
            esac
            ;;
        *) # EN
            case "$key" in
                "title") echo "Physical/Cloud Virtual Server OS DD Reinstaller" ;;
                "warn") echo "[CRITICAL WARNING] Direct DD disk overwriting might brick server. Back up your files!" ;;
                "opt_1") echo "DD Reinstall to Debian 12 (via LeitboGi0ro Engine)" ;;
                "opt_2") echo "DD Reinstall to Ubuntu 22.04 (via LeitboGi0ro Engine)" ;;
                "opt_3") echo "DD Reinstall to Alpine Linux (Lightweight OS)" ;;
                "opt_4") echo "DD Reinstall to Rocky Linux 9" ;;
                "start_dd") echo "Formatting drive boot partitions & launching installer script. Server will reboot..." ;;
                "creds_tip") echo "Default credential root password: LeitboGi0ro \nInfo: Reinstall takes 5-15 mins. Please check your cloud portal console." ;;
            esac
            ;;
    esac
}

run_leitbogioro_dd() {
    local os="$1"
    local ver="$2"
    echo -e "${gl_huang}$(get_dd_msg 'start_dd')${gl_bai}"
    echo -e "${gl_huang}$(get_dd_msg 'creds_tip')${gl_bai}"
    sleep 3

    # Download InstallNET scripts from LeitboGi0ro github repo
    wget --no-check-certificate -qO InstallNET.sh 'https://raw.githubusercontent.com/leitbogioro/Tools/master/Linux-NetInstall/InstallNET.sh'
    chmod +x InstallNET.sh
    # Execute reinstall
    bash InstallNET.sh -"$os" "$ver" -pwd 'LeitboGi0ro'
}

run_reinstall_bin() {
    local os="$1"
    local ver="$2"
    echo -e "${gl_huang}$(get_dd_msg 'start_dd')${gl_bai}"
    sleep 3
    # Utilizing bin456789 reinstall script logic
    curl -sSL -O https://raw.githubusercontent.com/bin456789/reinstall/main/reinstall.sh
    chmod +x reinstall.sh
    bash reinstall.sh "$os" "$ver"
    reboot
}

dd_menu() {
    while true; do
        clear
        echo -e "${gl_kjlan}========================================================================${gl_bai}"
        echo -e "                 $(get_dd_msg 'title')                                  "
        echo -e "${gl_kjlan}========================================================================${gl_bai}"
        echo -e "${gl_hong}$(get_dd_msg 'warn')${gl_bai}"
        echo -e "${gl_kjlan}------------------------------------------------------------------------${gl_bai}"
        echo -e "  ${gl_lv}1.${gl_bai} $(get_dd_msg 'opt_1')"
        echo -e "  ${gl_lv}2.${gl_bai} $(get_dd_msg 'opt_2')"
        echo -e "  ${gl_lv}3.${gl_bai} $(get_dd_msg 'opt_3')"
        echo -e "  ${gl_lv}4.${gl_bai} $(get_dd_msg 'opt_4')"
        echo -e "${gl_kjlan}------------------------------------------------------------------------${gl_bai}"
        echo -e "  ${gl_hong}0.${gl_bai} $(get_msg 'press_any_key')"
        echo -e "${gl_kjlan}========================================================================${gl_bai}"

        read -p "Selection: " sub_ch
        case "$sub_ch" in
            1) run_leitbogioro_dd "debian" "12"; exit 0 ;;
            2) run_leitbogioro_dd "ubuntu" "22.04"; exit 0 ;;
            3) run_leitbogioro_dd "alpine" ""; exit 0 ;;
            4) run_reinstall_bin "rocky" "9"; exit 0 ;;
            0) return ;;
            *) echo -e "${gl_hong}$(get_msg 'invalid_selection')${gl_bai}"; sleep 2 ;;
        esac
    done
}

dd_menu
