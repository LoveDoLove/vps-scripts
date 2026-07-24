#!/bin/bash
# scripts/system_tools.sh
# System Tools - System configuration, timezone, root passwd, ssh port, and locale
# Bilingual (CN / EN)

SCRIPT_PATH=$(dirname "$(readlink -f "$0")")
if [ -f "$SCRIPT_PATH/../lib/common.sh" ]; then
    . "$SCRIPT_PATH/../lib/common.sh"
elif [ -f "/tmp/vps-scripts/lib/common.sh" ]; then
    . "/tmp/vps-scripts/lib/common.sh"
fi

detect_language "$1"
require_root

# Translation lookup
get_sys_msg() {
    local key="$1"
    case "$LANG_ENV" in
        CN)
            case "$key" in
                "title") echo "系統環境配置與伺服器基本工具面板" ;;
                "opt_1") echo "修改伺服器主機名稱 (Hostname)" ;;
                "opt_2") echo "更改系統靜態解析 DNS (NameServers)" ;;
                "opt_3") echo "變更系統所在時區 (Timezone)" ;;
                "opt_4") echo "建立或重置虛擬記憶體 Swapfile" ;;
                "opt_5") echo "修改系統 root 帳戶管理密碼" ;;
                "opt_6") echo "開啟 / 停用 Root 遠端 SSH 金鑰登入方式" ;;
                "opt_7") echo "變更 SSH 連線監聽端口 (Port)" ;;
                "opt_8") echo "變更/修復 Linux 系統區域編碼 (Locale)" ;;
                "opt_9") echo "啟用或停用系統原生 IPv6 網路協議" ;;
                "opt_10") echo "安裝及查看 Fail2ban 防暴力破解工具" ;;
                "cur_hs") echo "當前主機名: " ;;
                "cur_dns") echo "當前解析 DNS: " ;;
                "cur_tz") echo "當前時區時間: " ;;
                "enter_hs") echo "請輸入新的主機名稱 (Hostname): " ;;
                "enter_dns") echo "請輸入主要與次要 DNS，以空格分開 (例如 8.8.8.8 1.1.1.1): " ;;
                "enter_pwd") echo "請輸入新的 root 密碼: " ;;
                "enter_ssh_p") echo "請輸入新的 SSH 端口號: " ;;
                "ssh_warn") echo "重設 SSH 端口前，請確保在雲服務控制台已放行對應端口，以免失聯！" ;;
                "fail2ban_ok") echo "Fail2ban 服務狀態已展示。" ;;
            esac
            ;;
        *) # EN
            case "$key" in
                "title") echo "System Tools & OS configuration dashboard" ;;
                "opt_1") echo "Change Machine Hostname" ;;
                "opt_2") echo "Modify System Static DNS Resolvers" ;;
                "opt_3") echo "Change Operating System Timezone" ;;
                "opt_4") echo "Configure or Resize Swapfile Memory" ;;
                "opt_5") echo "Update root security User Password" ;;
                "opt_6") echo "Toggle Root Remote SSH Logging Authority" ;;
                "opt_7") echo "Change Default SSH daemon Port" ;;
                "opt_8") echo "Update/Fix System Locale Encoding" ;;
                "opt_9") echo "Toggle IPv6 Network Protocol" ;;
                "opt_10") echo "Uninstall & Monitor Fail2ban Brute Force Defender" ;;
                "cur_hs") echo "Current Hostname: " ;;
                "cur_dns") echo "Current DNS Resolvers: " ;;
                "cur_tz") echo "Current System Time/Zone: " ;;
                "enter_hs") echo "Enter new host name: " ;;
                "enter_dns") echo "Enter Primary & Secondary resolvers (e.g. 8.8.8.8 1.1.1.1): " ;;
                "enter_pwd") echo "Enter new root password: " ;;
                "enter_ssh_p") echo "Enter new SSH Port number: " ;;
                "ssh_warn") echo "Security Alert! Make sure you open the new port on your cloud firewall console first!" ;;
                "fail2ban_ok") echo "Fail2ban daemon status displayed." ;;
            esac
            ;;
    esac
}

show_system_overview() {
    echo -e "$(get_sys_msg 'cur_hs') ${gl_huang}$(hostname)${gl_bai}"
    local dns_s=$(grep "^nameserver" /etc/resolv.conf | awk '{print $2}' | tr '\n' ' ')
    echo -e "$(get_sys_msg 'cur_dns') ${gl_lan}${dns_s}${gl_bai}"
    echo -e "$(get_sys_msg 'cur_tz') ${gl_lv}$(date)${gl_bai}"
}

upd_hostname() {
    read -p "$(get_sys_msg 'enter_hs')" new_hs
    if [ -n "$new_hs" ]; then
        hostnamectl set-hostname "$new_hs" 2>/dev/null || echo "$new_hs" > /etc/hostname
        echo "Hostname updated to $new_hs. Requires reconnecting terminal shell to display changes."
    fi
}

upd_dns() {
    read -p "$(get_sys_msg 'enter_dns')" dns1 dns2
    if [[ -n "$dns1" ]]; then
        echo -e "nameserver $dns1\nnameserver ${dns2:-8.8.8.8}" > /etc/resolv.conf
        echo "DNS updated successfully."
    fi
}

upd_timezone() {
    if command -v tzselect &>/dev/null; then
        dpkg-reconfigure tzdata 2>/dev/null || tzselect
    else
        # Fallback interactive manual selection
        local tz="UTC"
        if [[ "$LANG_ENV" == "CN" ]]; then
            tz="Asia/Shanghai"
        fi
        ln -sf "/usr/share/zoneinfo/$tz" /etc/localtime
    fi
}

upd_root_pwd() {
    read -p "$(get_sys_msg 'enter_pwd')" pwd_val
    if [ -n "$pwd_val" ]; then
        echo "root:$pwd_val" | chpasswd
        echo "Root password updated."
    fi
}

toggle_ssh_root() {
    local config_file="/etc/ssh/sshd_config"
    clear
    echo -e "PermitRootLogin SSH Setting:"
    echo -e "  ${gl_lv}1.${gl_bai} Enable Remote Root Login"
    echo -e "  ${gl_lv}2.${gl_bai} Disable Remote Root Login"
    read -p "Select: " root_ch

    case "$root_ch" in
        1)
            sed -i 's/^#*PermitRootLogin.*/PermitRootLogin yes/' "$config_file"
            sed -i 's/^#*PasswordAuthentication.*/PasswordAuthentication yes/' "$config_file"
            sys_service restart sshd 2>/dev/null || sys_service restart ssh 2>/dev/null
            echo "Remote root login enabled."
            ;;
        2)
            sed -i 's/^#*PermitRootLogin.*/PermitRootLogin no/' "$config_file"
            sys_service restart sshd 2>/dev/null || sys_service restart ssh 2>/dev/null
            echo "Remote root login disabled."
            ;;
    esac
}

upd_ssh_port() {
    local port_val
    echo -e "${gl_hong}$(get_sys_msg 'ssh_warn')${gl_bai}"
    read -p "$(get_sys_msg 'enter_ssh_p')" port_val

    if [[ "$port_val" =~ ^[0-9]+$ ]]; then
        sed -i "s/^#*Port.*/Port $port_val/g" /etc/ssh/sshd_config
        sys_service restart sshd 2>/dev/null || sys_service restart ssh 2>/dev/null
        echo -e "${gl_lv}SSH Port updated to: $port_val${gl_bai}"
    fi
}

upd_locale() {
    install_pkgs locales locales-all 2>/dev/null
    if [[ "$LANG_ENV" == "CN" ]]; then
        locale-gen zh_CN.UTF-8 2>/dev/null
        export LANG=zh_CN.UTF-8
        update-locale LANG=zh_CN.UTF-8 2>/dev/null
    else
        locale-gen en_US.UTF-8 2>/dev/null
        export LANG=en_US.UTF-8
        update-locale LANG=en_US.UTF-8 2>/dev/null
    fi
    echo "Locales configured."
}

toggle_ipv6() {
    clear
    echo -e "IPv6 Networking Management:"
    echo -e "  ${gl_lv}1.${gl_bai} Enable IPv6 Support"
    echo -e "  ${gl_lv}2.${gl_bai} Disable IPv6 Support"
    read -p "Select: " ip_ch

    case "$ip_ch" in
        1)
            sed -i '/net.ipv6.conf.all.disable_ipv6/d' /etc/sysctl.conf
            sed -i '/net.ipv6.conf.default.disable_ipv6/d' /etc/sysctl.conf
            sysctl -p >/dev/null 2>&1
            echo "IPv6 protocol enabled."
            ;;
        2)
            echo "net.ipv6.conf.all.disable_ipv6 = 1" >> /etc/sysctl.conf
            echo "net.ipv6.conf.default.disable_ipv6 = 1" >> /etc/sysctl.conf
            sysctl -p >/dev/null 2>&1
            echo "IPv6 protocol disabled."
            ;;
    esac
}

fail2ban_panel() {
    clear
    echo -e "Fail2ban SSH brute-force defense console:"
    echo -e "  ${gl_lv}1.${gl_bai} Install Fail2ban daemon"
    echo -e "  ${gl_lv}2.${gl_bai} Monitor current Fail2ban status"
    echo -e "  ${gl_lv}3.${gl_bai} Completely uninstall Fail2ban"
    read -p "Select: " f_ch

    case "$f_ch" in
        1)
            install_pkgs fail2ban
            sys_service start fail2ban 2>/dev/null
            sys_service enable fail2ban 2>/dev/null
            ;;
        2)
            if command -v fail2ban-client &>/dev/null; then
                fail2ban-client status sshd 2>/dev/null || fail2ban-client status
            else
                echo "Fail2ban is not installed."
            fi
            ;;
        3)
            remove_pkgs fail2ban
            rm -rf /etc/fail2ban
            ;;
    esac
}

sys_menu() {
    while true; do
        clear
        echo -e "${gl_kjlan}========================================================================${gl_bai}"
        echo -e "                 $(get_sys_msg 'title')                                 "
        echo -e "${gl_kjlan}========================================================================${gl_bai}"
        show_system_overview
        echo -e "${gl_kjlan}------------------------------------------------------------------------${gl_bai}"
        echo -e "  ${gl_lv}1.${gl_bai} $(get_sys_msg 'opt_1')          ${gl_lv}6.${gl_bai} $(get_sys_msg 'opt_6')"
        echo -e "  ${gl_lv}2.${gl_bai} $(get_sys_msg 'opt_2')          ${gl_lv}7.${gl_bai} $(get_sys_msg 'opt_7')"
        echo -e "  ${gl_lv}3.${gl_bai} $(get_sys_msg 'opt_3')          ${gl_lv}8.${gl_bai} $(get_sys_msg 'opt_8')"
        echo -e "  ${gl_lv}4.${gl_bai} $(get_sys_msg 'opt_4')          ${gl_lv}9.${gl_bai} $(get_sys_msg 'opt_9')"
        echo -e "  ${gl_lv}5.${gl_bai} $(get_sys_msg 'opt_5')         ${gl_lv}10.${gl_bai} $(get_sys_msg 'opt_10')"
        echo -e "${gl_kjlan}------------------------------------------------------------------------${gl_bai}"
        echo -e "  ${gl_hong}0.${gl_bai} $(get_msg 'press_any_key')"
        echo -e "${gl_kjlan}========================================================================${gl_bai}"

        read -p "Selection: " sub_ch
        case "$sub_ch" in
            1) upd_hostname; break_end ;;
            2) upd_dns; break_end ;;
            3) upd_timezone; break_end ;;
            4) read -p "Swap Size in MB: " s_mb && add_swap "$s_mb"; break_end ;;
            5) upd_root_pwd; break_end ;;
            6) toggle_ssh_root; break_end ;;
            7) upd_ssh_port; break_end ;;
            8) upd_locale; break_end ;;
            9) toggle_ipv6; break_end ;;
            10) fail2ban_panel; break_end ;;
            0) return ;;
            *) echo -e "${gl_hong}$(get_msg 'invalid_selection')${gl_bai}"; sleep 2 ;;
        esac
    done
}

sys_menu
