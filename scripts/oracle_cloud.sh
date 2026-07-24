#!/bin/bash
# scripts/oracle_cloud.sh
# Oracle Cloud Instance Specific Utilities & Optimizations
# Bilingual (CN / EN)

SCRIPT_PATH=$(dirname "$(readlink -f "$0")")
if [ -f "$SCRIPT_PATH/../lib/common.sh" ]; then
    . "$SCRIPT_PATH/../lib/common.sh"
elif [ -f "/tmp/vps-scripts/lib/common.sh" ]; then
    . "/tmp/vps-scripts/lib/common.sh"
fi

detect_language "$1"
require_root

get_oci_msg() {
    local key="$1"
    case "$LANG_ENV" in
        CN)
            case "$key" in
                "title") echo "甲骨文雲 (Oracle Cloud) 特有實體組態優化面板" ;;
                "opt_1") echo "開放本地防火牆所有網絡端口 (ACCEPT All Ports)" ;;
                "opt_2") echo "卸載並關閉 Oracle 雲端原廠監控守護進程 (Uninstall Agents)" ;;
                "opt_3") echo "配置網絡支持 IPv6 協議存取" ;;
                "opt_4") echo "停用網絡 IPv6 協議存取" ;;
                "opt_5") echo "執行系統引導硬盤分區熱擴容 (growpart)" ;;
                "opt_6") echo "新建 / 調整系統虛擬 swapfile 記憶體空間" ;;
                "opt_7") echo "一鍵磁碟引導 DD 重新安裝純淨版操作系統" ;;
                "ports_ok") echo "已刷新系統 iptables 規則放行本機全部 TCP/UDP 流量。" ;;
                "agent_removed") echo "甲骨文原廠監控組件(Oracle Cloud Agent)已解除安裝。" ;;
                "disk_expanding") echo "正在偵測磁碟並進行硬碟熱擴容分區作業..." ;;
                "disk_expanded") echo "引導磁碟擴容完成！" ;;
                "confirm_dd") echo "【重要警告】此操作將徹底清空硬盤重新部署操作系統。確認請輸入大寫 'YES': " ;;
            esac
            ;;
        *) # EN
            case "$key" in
                "title") echo "Oracle Cloud Instances Optimizations Panel" ;;
                "opt_1") echo "Open All Local Firewall Ports (Allow Incoming TCP/UDP)" ;;
                "opt_2") echo "Uninstall & Stop Oracle Cloud Agent (Improve Performance)" ;;
                "opt_3") echo "Enable IPv6 Networking support" ;;
                "opt_4") echo "Disable IPv6 Networking support" ;;
                "opt_5") echo "Perform Live Disk Partition Heat Expansion (growpart)" ;;
                "opt_6") echo "Configure or Resize local swapfile memory space" ;;
                "opt_7") echo "Launch Direct DD disk reinstallation script" ;;
                "ports_ok") echo "All iptables ports rules configured to ACCEPT incoming traffic." ;;
                "agent_removed") echo "Oracle Cloud monitoring agent uninstalled." ;;
                "disk_expanding") echo "Detecting layout & launching hot resize on boot drive..." ;;
                "disk_expanded") echo "Boot volume partition layout expanded successfully!" ;;
                "confirm_dd") echo "[WARNING] This procedure will format the system drive. Type uppercase 'YES' to proceed: " ;;
            esac
            ;;
    esac
}

open_all_ports() {
    # ACCEPT all standard iptables
    iptables -F
    iptables -X
    iptables -P INPUT ACCEPT
    iptables -P FORWARD ACCEPT
    iptables -P OUTPUT ACCEPT

    ip6tables -F 2>/dev/null
    ip6tables -X 2>/dev/null
    ip6tables -P INPUT ACCEPT 2>/dev/null
    ip6tables -P FORWARD ACCEPT 2>/dev/null
    ip6tables -P OUTPUT ACCEPT 2>/dev/null

    mkdir -p /etc/iptables 2>/dev/null
    iptables-save > /etc/iptables/rules.v4
    ip6tables-save > /etc/iptables/rules.v6 2>/dev/null
    echo -e "${gl_lv}$(get_oci_msg 'ports_ok')${gl_bai}"
}

remove_oracle_monitoring() {
    echo "Stopping and purging oracle-cloud-agent..."
    systemctl stop oracle-cloud-agent 2>/dev/null
    systemctl disable oracle-cloud-agent 2>/dev/null
    systemctl stop oracle-cloud-agent-updater 2>/dev/null
    systemctl disable oracle-cloud-agent-updater 2>/dev/null

    # Uninstall agent
    local pm=$(detect_pm)
    case "$pm" in
        apt)
            DEBIAN_FRONTEND=noninteractive apt-get purge -y oracle-cloud-agent 2>/dev/null
            ;;
        dnf|yum)
            dnf remove -y oracle-cloud-agent 2>/dev/null || yum remove -y oracle-cloud-agent 2>/dev/null
            ;;
    esac
    echo -e "${gl_lv}$(get_oci_msg 'agent_removed')${gl_bai}"
}

resize_boot_volume() {
    echo -e "${gl_huang}$(get_oci_msg 'disk_expanding')${gl_bai}"

    # Identify root partition device
    local root_dev=$(mount | grep ' / ' | awk '{print $1}')
    local disk_dev=$(echo "$root_dev" | sed -r 's/p?[0-9]+$//')
    local part_num=$(echo "$root_dev" | grep -o '[0-9]*$')

    # Install growpart utilities if missing
    if ! command -v growpart &>/dev/null; then
        install_pkgs cloud-guest-utils 2>/dev/null || install_pkgs cloud-utils-growpart
    fi

    growpart "$disk_dev" "$part_num" 2>/dev/null

    # Resize filesystem layers
    if command -v resize2fs &>/dev/null; then
        resize2fs "$root_dev" 2>/dev/null
    elif command -v xfs_growfs &>/dev/null; then
        xfs_growfs / 2>/dev/null
    fi

    echo -e "${gl_lv}$(get_oci_msg 'disk_expanded')${gl_bai}"
    df -h /
}

setup_sw() {
    read -p "Enter Swap size in MB: " s_mb
    if [[ "$s_mb" =~ ^[0-9]+$ ]]; then
        add_swap "$s_mb"
    fi
}

launch_dd() {
    clear
    echo -e "${gl_hong}==================================================${gl_bai}"
    read -p "$(get_oci_msg 'confirm_dd')" conf_val
    if [[ "$conf_val" == "YES" ]]; then
        # Launch direct reinstall scripts to Debian 12
        echo "Starting network installation pipeline..."
        wget --no-check-certificate -qO InstallNET.sh 'https://raw.githubusercontent.com/leitbogioro/Tools/master/Linux-NetInstall/InstallNET.sh'
        chmod +x InstallNET.sh
        bash InstallNET.sh -debian 12 -pwd 'LeitboGi0ro'
    fi
}

oci_menu() {
    while true; do
        clear
        echo -e "${gl_kjlan}========================================================================${gl_bai}"
        echo -e "                 $(get_oci_msg 'title')                                 "
        echo -e "${gl_kjlan}========================================================================${gl_bai}"
        echo -e "  ${gl_lv}1.${gl_bai} $(get_oci_msg 'opt_1')"
        echo -e "  ${gl_lv}2.${gl_bai} $(get_oci_msg 'opt_2')"
        echo -e "  ${gl_lv}5.${gl_bai} $(get_oci_msg 'opt_5')"
        echo -e "  ${gl_lv}6.${gl_bai} $(get_oci_msg 'opt_6')"
        echo -e "  ${gl_lv}7.${gl_bai} ${gl_hong}$(get_oci_msg 'opt_7')${gl_bai}"
        echo -e "${gl_kjlan}------------------------------------------------------------------------${gl_bai}"
        echo -e "  ${gl_hong}0.${gl_bai} $(get_msg 'press_any_key')"
        echo -e "${gl_kjlan}========================================================================${gl_bai}"

        read -p "Selection: " sub_ch
        case "$sub_ch" in
            1) open_all_ports; break_end ;;
            2) remove_oracle_monitoring; break_end ;;
            5) resize_boot_volume; break_end ;;
            6) setup_sw; break_end ;;
            7) launch_dd ;;
            0) return ;;
            *) echo -e "${gl_hong}$(get_msg 'invalid_selection')${gl_bai}"; sleep 2 ;;
        esac
    done
}

oci_menu
