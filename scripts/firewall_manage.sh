#!/bin/bash
# scripts/firewall_manage.sh
# Firewall and Advanced Security Management Module
# Bilingual (CN / EN)

SCRIPT_PATH=$(dirname "$(readlink -f "$0")")
if [ -f "$SCRIPT_PATH/../lib/common.sh" ]; then
    . "$SCRIPT_PATH/../lib/common.sh"
elif [ -f "/tmp/vps-scripts/lib/common.sh" ]; then
    . "/tmp/vps-scripts/lib/common.sh"
fi

detect_language "$1"
require_root
install_pkgs iptables ipset wget

# Local message definitions
get_fw_msg() {
    local key="$1"
    case "$LANG_ENV" in
        CN)
            case "$key" in
                "title") echo "高級防火牆與安防管理控制台" ;;
                "fw_list") echo "--- 當前 INPUT 鏈規則 ---" ;;
                "opt_1") echo "開放指定端口" ;;
                "opt_2") echo "關閉指定端口" ;;
                "opt_3") echo "開放所有端口 (僅保留 SSH)" ;;
                "opt_4") echo "屏蔽所有端口 (僅保留 SSH)" ;;
                "opt_5") echo "IP 白名單 (信任放行)" ;;
                "opt_6") echo "IP 黑名單 (永久封禁)" ;;
                "opt_7") echo "清除指定 IP 規則" ;;
                "opt_11") echo "允許 PING 響應" ;;
                "opt_12") echo "禁止 PING 響應" ;;
                "opt_13") echo "啟用 TCP/UDP DDoS 洪水防禦限制" ;;
                "opt_14") echo "停用 TCP/UDP DDoS 洪水防禦限制" ;;
                "opt_15") echo "一鍵封鎖特定國家 IP 段" ;;
                "opt_16") echo "一鍵僅允許特定國家 IP 訪問" ;;
                "opt_17") echo "解除特定國家 IP 段封鎖" ;;
                "enter_port") echo "請輸入端口號 (多個端口用空格隔開): " ;;
                "enter_ip") echo "請輸入 IP 地址或網段 (例如 192.168.1.1 10.0.0.0/24): " ;;
                "enter_cc") echo "請輸入國家代碼 (ISO 兩位，例如 CN US JP，多個用空格隔開): " ;;
                "save_rules") echo "正在存檔防火牆規則，並設定開機自動重載..." ;;
                "ssh_port_found") echo "偵測到當前 SSH 端口為: " ;;
                "allow_ping") echo "外部 Ping 響應已開啟。" ;;
                "block_ping") echo "外部 Ping 響應已屏蔽。" ;;
                "ddos_on") echo "DDoS 洪水防禦限制已開啟。" ;;
                "ddos_off") echo "DDoS 洪水防禦限制已停用。" ;;
                "cc_block_ok") echo "已成功封鎖該國家 IP 流量。" ;;
                "cc_allow_ok") echo "已設置僅允許該國家 IP 流量，其它均屏蔽。" ;;
                "cc_clear_ok") echo "已成功接触該國家 IP 流量限制。" ;;
            esac
            ;;
        *) # EN
            case "$key" in
                "title") echo "Advanced Firewall & Security Management" ;;
                "fw_list") echo "--- Current INPUT Chain Rules ---" ;;
                "opt_1") echo "Open Specific Port(s)" ;;
                "opt_2") echo "Close Specific Port(s)" ;;
                "opt_3") echo "Open All Ports (Except securing SSH)" ;;
                "opt_4") echo "Close All Ports (Except securing SSH)" ;;
                "opt_5") echo "Allow IP(s) White List" ;;
                "opt_6") echo "Block IP(s) Black List" ;;
                "opt_7") echo "Clear custom rules for IP" ;;
                "opt_11") echo "Allow incoming Ping ICMP requests" ;;
                "opt_12") echo "Disable incoming Ping ICMP requests" ;;
                "opt_13") echo "Enable TCP/UDP DDoS limiting defense" ;;
                "opt_14") echo "Disable TCP/UDP DDoS limiting defense" ;;
                "opt_15") echo "Block specific countries IP blocks" ;;
                "opt_16") echo "Allow ONLY specific countries IP blocks" ;;
                "opt_17") echo "Unblock specific countries IP blocks" ;;
                "enter_port") echo "Please enter port(s) (space separated): " ;;
                "enter_ip") echo "Please enter IP address or block (e.g. 192.168.1.1 10.0.0.0/24): " ;;
                "enter_cc") echo "Please enter Country Code (ISO 2-letter, e.g. CN US JP, space separated): " ;;
                "save_rules") echo "Saving iptables rules & arranging cron-persist at reboot..." ;;
                "ssh_port_found") echo "Detected active SSH port: " ;;
                "allow_ping") echo "Income ping requests enabled." ;;
                "block_ping") echo "Income ping requests disabled." ;;
                "ddos_on") echo "DDoS speed limit policies applied." ;;
                "ddos_off") echo "DDoS speed limit policies disabled." ;;
                "cc_block_ok") echo "Successfully blocked selected country IP block." ;;
                "cc_allow_ok") echo "Successfully locked interface to selected country IP only." ;;
                "cc_clear_ok") echo "Successfully removed restrictions for selected country." ;;
            esac
            ;;
    esac
}

# Auto persist firewall rules on reboot
save_iptables_rules() {
    echo -e "${gl_huang}$(get_fw_msg 'save_rules')${gl_bai}"
    mkdir -p /etc/iptables 2>/dev/null
    iptables-save > /etc/iptables/rules.v4
    ip6tables-save > /etc/iptables/rules.v6 2>/dev/null

    # Setup automatic load cronjob for persistent rules
    if command -v crontab &>/dev/null; then
        crontab -l 2>/dev/null | grep -v 'iptables-restore' | crontab -
        (crontab -l 2>/dev/null; echo '@reboot /sbin/iptables-restore < /etc/iptables/rules.v4') | crontab -
    fi
}

# Detect system running SSH port
get_ssh_port() {
    local port=$(grep -E '^\s*Port [0-9]+' /etc/ssh/sshd_config | awk '{print $2}')
    echo "${port:-22}"
}

open_port() {
    local ports=($@)
    for p in "${ports[@]}"; do
        iptables -D INPUT -p tcp --dport "$p" -j DROP 2>/dev/null
        iptables -D INPUT -p udp --dport "$p" -j DROP 2>/dev/null
        if ! iptables -C INPUT -p tcp --dport "$p" -j ACCEPT 2>/dev/null; then
            iptables -I INPUT 1 -p tcp --dport "$p" -j ACCEPT
        fi
        if ! iptables -C INPUT -p udp --dport "$p" -j ACCEPT 2>/dev/null; then
            iptables -I INPUT 1 -p udp --dport "$p" -j ACCEPT
        fi
    done
    save_iptables_rules
}

close_port() {
    local ports=($@)
    for p in "${ports[@]}"; do
        iptables -D INPUT -p tcp --dport "$p" -j ACCEPT 2>/dev/null
        iptables -D INPUT -p udp --dport "$p" -j ACCEPT 2>/dev/null
        if ! iptables -C INPUT -p tcp --dport "$p" -j DROP 2>/dev/null; then
            iptables -I INPUT 1 -p tcp --dport "$p" -j DROP
        fi
        if ! iptables -C INPUT -p udp --dport "$p" -j DROP 2>/dev/null; then
            iptables -I INPUT 1 -p udp --dport "$p" -j DROP
        fi
    done
    save_iptables_rules
}

allow_ip() {
    local ips=($@)
    for ip in "${ips[@]}"; do
        iptables -D INPUT -s "$ip" -j DROP 2>/dev/null
        if ! iptables -C INPUT -s "$ip" -j ACCEPT 2>/dev/null; then
            iptables -I INPUT 1 -s "$ip" -j ACCEPT
        fi
    done
    save_iptables_rules
}

block_ip() {
    local ips=($@)
    for ip in "${ips[@]}"; do
        iptables -D INPUT -s "$ip" -j ACCEPT 2>/dev/null
        if ! iptables -C INPUT -s "$ip" -j DROP 2>/dev/null; then
            iptables -I INPUT 1 -s "$ip" -j DROP
        fi
    done
    save_iptables_rules
}

clear_ip() {
    local ips=($@)
    for ip in "${ips[@]}"; do
        iptables -D INPUT -s "$ip" -j ACCEPT 2>/dev/null
        iptables -D INPUT -s "$ip" -j DROP 2>/dev/null
    done
    save_iptables_rules
}

enable_ddos() {
    # Web and server DDoS flooding protection policies using Syn rate-limit
    iptables -D DOCKER-USER -p tcp --syn -m limit --limit 500/s --limit-burst 100 -j ACCEPT 2>/dev/null
    iptables -D DOCKER-USER -p tcp --syn -j DROP 2>/dev/null
    iptables -D DOCKER-USER -p udp -m limit --limit 3000/s -j ACCEPT 2>/dev/null
    iptables -D DOCKER-USER -p udp -j DROP 2>/dev/null

    iptables -A INPUT -p tcp --syn -m limit --limit 500/s --limit-burst 100 -j ACCEPT
    iptables -A INPUT -p tcp --syn -j DROP
    iptables -A INPUT -p udp -m limit --limit 3000/s -j ACCEPT
    iptables -A INPUT -p udp -j DROP
    save_iptables_rules
    echo -e "${gl_lv}$(get_fw_msg 'ddos_on')${gl_bai}"
}

disable_ddos() {
    iptables -D INPUT -p tcp --syn -m limit --limit 500/s --limit-burst 100 -j ACCEPT 2>/dev/null
    iptables -D INPUT -p tcp --syn -j DROP 2>/dev/null
    iptables -D INPUT -p udp -m limit --limit 3000/s -j ACCEPT 2>/dev/null
    iptables -D INPUT -p udp -j DROP 2>/dev/null
    save_iptables_rules
    echo -e "${gl_lv}$(get_fw_msg 'ddos_off')${gl_bai}"
}

manage_country_rules() {
    local action="$1"
    shift
    local countries=($@)

    for cc in "${countries[@]}"; do
        local ipset_name="${cc,,}_block"
        local fallback_url="https://www.ipdeny.com/ipblocks/data/countries/${cc,,}.zone"

        case "$action" in
            block)
                if ! ipset list "$ipset_name" &>/dev/null; then
                    ipset create "$ipset_name" hash:net
                fi
                wget -q --timeout=10 "$fallback_url" -O "/tmp/${cc,,}.zone"
                if [ -s "/tmp/${cc,,}.zone" ]; then
                    while read -r ip; do
                        ipset add "$ipset_name" "$ip" 2>/dev/null
                    done < "/tmp/${cc,,}.zone"
                    iptables -I INPUT -m set --match-set "$ipset_name" src -j DROP
                    echo -e "${gl_lv}$(get_fw_msg 'cc_block_ok') : $cc${gl_bai}"
                fi
                rm -f "/tmp/${cc,,}.zone"
                ;;
            allow)
                if ! ipset list "$ipset_name" &>/dev/null; then
                    ipset create "$ipset_name" hash:net
                fi
                wget -q --timeout=10 "$fallback_url" -O "/tmp/${cc,,}.zone"
                if [ -s "/tmp/${cc,,}.zone" ]; then
                    ipset flush "$ipset_name"
                    while read -r ip; do
                        ipset add "$ipset_name" "$ip" 2>/dev/null
                    done < "/tmp/${cc,,}.zone"
                    iptables -P INPUT DROP
                    iptables -A INPUT -m set --match-set "$ipset_name" src -j ACCEPT
                    echo -e "${gl_lv}$(get_fw_msg 'cc_allow_ok') : $cc${gl_bai}"
                fi
                rm -f "/tmp/${cc,,}.zone"
                ;;
            unblock)
                iptables -D INPUT -m set --match-set "$ipset_name" src -j DROP 2>/dev/null
                iptables -D INPUT -m set --match-set "$ipset_name" src -j ACCEPT 2>/dev/null
                ipset destroy "$ipset_name" 2>/dev/null
                echo -e "${gl_lv}$(get_fw_msg 'cc_clear_ok') : $cc${gl_bai}"
                ;;
        esac
    done
    save_iptables_rules
}

# Main Command loop for module
firewall_menu() {
    while true; do
        clear
        echo -e "${gl_kjlan}========================================================================${gl_bai}"
        echo -e "                 $(get_fw_msg 'title')                                  "
        echo -e "${gl_kjlan}========================================================================${gl_bai}"
        echo -e "$(get_fw_msg 'fw_list')"
        # Print a short preview of the firewall rules (Limit 12 lines)
        iptables -L INPUT -n --line-numbers 2>/dev/null | head -n 12
        echo "..."
        echo -e "${gl_kjlan}------------------------------------------------------------------------${gl_bai}"
        echo -e "  ${gl_lv}1.${gl_bai} $(get_fw_msg 'opt_1')          ${gl_lv}5.${gl_bai} $(get_fw_msg 'opt_5')"
        echo -e "  ${gl_lv}2.${gl_bai} $(get_fw_msg 'opt_2')          ${gl_lv}6.${gl_bai} $(get_fw_msg 'opt_6')"
        echo -e "  ${gl_lv}3.${gl_bai} $(get_fw_msg 'opt_3')  ${gl_lv}7.${gl_bai} $(get_fw_msg 'opt_7')"
        echo -e "  ${gl_lv}4.${gl_bai} $(get_fw_msg 'opt_4')"
        echo -e "  ${gl_kjlan}------------------------------------------------------------------------${gl_bai}"
        echo -e " ${gl_lv}11.${gl_bai} $(get_fw_msg 'opt_11')       ${gl_lv}15.${gl_bai} $(get_fw_msg 'opt_15')"
        echo -e " ${gl_lv}12.${gl_bai} $(get_fw_msg 'opt_12')       ${gl_lv}16.${gl_bai} $(get_fw_msg 'opt_16')"
        echo -e " ${gl_lv}13.${gl_bai} $(get_fw_msg 'opt_13')  ${gl_lv}17.${gl_bai} $(get_fw_msg 'opt_17')"
        echo -e " ${gl_lv}14.${gl_bai} $(get_fw_msg 'opt_14')"
        echo -e "${gl_kjlan}------------------------------------------------------------------------${gl_bai}"
        echo -e "  ${gl_hong}0.${gl_bai} $(get_msg 'press_any_key')"
        echo -e "${gl_kjlan}========================================================================${gl_bai}"

        read -p "Selection: " sub_ch
        case "$sub_ch" in
            1)
                read -p "$(get_fw_msg 'enter_port')" inp_ports
                open_port $inp_ports
                break_end
                ;;
            2)
                read -p "$(get_fw_msg 'enter_port')" inp_ports
                close_port $inp_ports
                break_end
                ;;
            3)
                # Flush everything, allow SSH port only
                local sshp=$(get_ssh_port)
                iptables -F
                iptables -P INPUT ACCEPT
                iptables -P FORWARD ACCEPT
                iptables -P OUTPUT ACCEPT
                iptables -A INPUT -i lo -j ACCEPT
                iptables -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT
                iptables -A INPUT -p tcp --dport "$sshp" -j ACCEPT
                save_iptables_rules
                break_end
                ;;
            4)
                # Drop everything, allow SSH port only
                local sshp=$(get_ssh_port)
                iptables -F
                iptables -P INPUT DROP
                iptables -P FORWARD DROP
                iptables -P OUTPUT ACCEPT
                iptables -A INPUT -i lo -j ACCEPT
                iptables -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT
                iptables -A INPUT -p tcp --dport "$sshp" -j ACCEPT
                save_iptables_rules
                break_end
                ;;
            5)
                read -p "$(get_fw_msg 'enter_ip')" inp_ips
                allow_ip $inp_ips
                break_end
                ;;
            6)
                read -p "$(get_fw_msg 'enter_ip')" inp_ips
                block_ip $inp_ips
                break_end
                ;;
            7)
                read -p "$(get_fw_msg 'enter_ip')" inp_ips
                clear_ip $inp_ips
                break_end
                ;;
            11)
                iptables -D INPUT -p icmp --icmp-type echo-request -j DROP 2>/dev/null
                iptables -I INPUT 1 -p icmp --icmp-type echo-request -j ACCEPT
                save_iptables_rules
                echo -e "${gl_lv}$(get_fw_msg 'allow_ping')${gl_bai}"
                break_end
                ;;
            12)
                iptables -D INPUT -p icmp --icmp-type echo-request -j ACCEPT 2>/dev/null
                iptables -I INPUT 1 -p icmp --icmp-type echo-request -j DROP
                save_iptables_rules
                echo -e "${gl_lv}$(get_fw_msg 'block_ping')${gl_bai}"
                break_end
                ;;
            13)
                enable_ddos
                break_end
                ;;
            14)
                disable_ddos
                break_end
                ;;
            15)
                read -p "$(get_fw_msg 'enter_cc')" country_codes
                manage_country_rules block $country_codes
                break_end
                ;;
            16)
                read -p "$(get_fw_msg 'enter_cc')" country_codes
                manage_country_rules allow $country_codes
                break_end
                ;;
            17)
                read -p "$(get_fw_msg 'enter_cc')" country_codes
                manage_country_rules unblock $country_codes
                break_end
                ;;
            0) return ;;
            *) echo -e "${gl_hong}$(get_msg 'invalid_selection')${gl_bai}"; sleep 2 ;;
        esac
    done
}

firewall_menu
