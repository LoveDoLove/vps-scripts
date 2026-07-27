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

# ============================================================
# Local message definitions
# ============================================================
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
                "opt_5") echo "白名單管理" ;;
                "opt_6") echo "查看端口開放狀態" ;;
                "opt_7") echo "查看本機網路連接狀態" ;;
                "opt_8") echo "查看本機 IPv4/6 地址" ;;
                "opt_9") echo "DDOS 防護" ;;
                "opt_10") echo "啟用國家 IP 封鎖/放行" ;;
                "opt_11") echo "啟用 Nginx CC 攻擊防護" ;;
                "opt_12") echo "啟用 ModSecurity WAF" ;;
                "opt_13") echo "端口/IP 黑白名單管理" ;;
                "enter_port") echo "請輸入端口號: " ;;
                "invalid_port") echo "端口格式無效，跳過。" ;;
                "open_success") echo "端口已開放。" ;;
                "close_success") echo "端口已關閉。" ;;
                "all_open") echo "已開放所有端口。" ;;
                "all_close") echo "已屏蔽所有端口，僅保留 SSH 端口。" ;;
                "enter_cc") echo "請輸入國家代碼 (ISO 3166-1 alpha-2, 多個用空格分隔) : " ;;
                "cc_block") echo "已封鎖指定國家的 IP。" ;;
                "cc_allow") echo "已放行指定國家的 IP。" ;;
                "cc_unblock") echo "已解除封鎖指定國家的 IP。" ;;
                "ddos_on") echo "DDOS 防護已啟用。" ;;
                "ddos_off") echo "DDOS 防護已關閉。" ;;
                "block_ping") echo "已禁止 Ping。" ;;
                "allow_ping") echo "已允許 Ping。" ;;
                "cc_on") echo "Nginx CC 防護已啟用。" ;;
                "cc_off") echo "Nginx CC 防護已關閉。" ;;
                "waf_on") echo "ModSecurity WAF 已啟用。" ;;
                "waf_off") echo "ModSecurity WAF 已關閉。" ;;
                "acl_title") echo "端口/IP 黑白名單管理" ;;
                "acl_allow_port") echo "放行指定端口" ;;
                "acl_block_port") echo "封鎖指定端口" ;;
                "acl_allow_ip") echo "放行指定 IP" ;;
                "acl_block_ip") echo "封鎖指定 IP" ;;
                "acl_list") echo "查看當前規則" ;;
            esac
            ;;
        *)
            case "$key" in
                "title") echo "Advanced Firewall & Security Console" ;;
                "fw_list") echo "--- Current INPUT Chain Rules ---" ;;
                "opt_1") echo "Open a port" ;;
                "opt_2") echo "Close a port" ;;
                "opt_3") echo "Open all ports (SSH only kept)" ;;
                "opt_4") echo "Close all ports (SSH only kept)" ;;
                "opt_5") echo "Whitelist management" ;;
                "opt_6") echo "View open port status" ;;
                "opt_7") echo "View local connection status" ;;
                "opt_8") echo "View local IPv4/IPv6 addresses" ;;
                "opt_9") echo "DDoS protection" ;;
                "opt_10") echo "Country IP block/allow management" ;;
                "opt_11") echo "Enable Nginx CC attack protection" ;;
                "opt_12") echo "Enable ModSecurity WAF" ;;
                "opt_13") echo "Port/IP blacklist/whitelist management" ;;
                "enter_port") echo "Enter port number: " ;;
                "invalid_port") echo "Invalid port, skipped." ;;
                "open_success") echo "Port opened." ;;
                "close_success") echo "Port closed." ;;
                "all_open") echo "All ports opened." ;;
                "all_close") echo "All ports closed, only SSH port kept." ;;
                "enter_cc") echo "Enter country code (ISO 3166-1 alpha-2, space-separated): " ;;
                "cc_block") echo "Blocked specified countries." ;;
                "cc_allow") echo "Allowed specified countries." ;;
                "cc_unblock") echo "Unblocked specified countries." ;;
                "ddos_on") echo "DDoS protection enabled." ;;
                "ddos_off") echo "DDoS protection disabled." ;;
                "block_ping") echo "Ping blocked." ;;
                "allow_ping") echo "Ping allowed." ;;
                "cc_on") echo "Nginx CC protection enabled." ;;
                "cc_off") echo "Nginx CC protection disabled." ;;
                "waf_on") echo "ModSecurity WAF enabled." ;;
                "waf_off") echo "ModSecurity WAF disabled." ;;
                "acl_title") echo "Port/IP Blacklist/Whitelist Management" ;;
                "acl_allow_port") echo "Allow a port" ;;
                "acl_block_port") echo "Block a port" ;;
                "acl_allow_ip") echo "Allow an IP address" ;;
                "acl_block_ip") echo "Block an IP address" ;;
                "acl_list") echo "View current rules" ;;
            esac
            ;;
    esac
}

# ============================================================
# Core firewall functions
# ============================================================

save_iptables_rules() {
    if command -v iptables-save &>/dev/null; then
        mkdir -p /etc/iptables
        iptables-save > /etc/iptables/rules.v4 2>/dev/null
        if command -v ip6tables-save &>/dev/null; then
            ip6tables-save > /etc/iptables/rules.v6 2>/dev/null
        fi
    fi
}

add_whitelist() {
    local ip="$1"
    iptables -C INPUT -s "$ip" -j ACCEPT 2>/dev/null || iptables -I INPUT 1 -s "$ip" -j ACCEPT
    save_iptables_rules
}

whitelist_menu() {
    while true; do
        clear
        echo -e "${gl_kjlan}$(get_fw_msg 'title')${gl_bai}"
        echo -e "${gl_lv}1.${gl_bai} $(get_fw_msg 'opt_5') - $(get_fw_msg 'acl_allow_ip')"
        echo -e "${gl_lv}2.${gl_bai} $(get_fw_msg 'opt_5') - $(get_fw_msg 'acl_list')"
        echo -e "${gl_hong}0.${gl_bai} $(get_msg 'back')"
        read -p "Selection: " wl_ch
        case "$wl_ch" in
            1)
                read -p "Enter IP to whitelist: " wl_ip
                add_whitelist "$wl_ip"
                echo -e "${gl_lv}IP $wl_ip whitelisted.${gl_bai}"
                break_end
                ;;
            2)
                echo -e "${gl_kjlan}$(get_fw_msg 'fw_list')${gl_bai}"
                iptables -L INPUT -n --line-numbers 2>/dev/null | head -30
                break_end
                ;;
            0) return ;;
            *) echo -e "${gl_hong}$(get_msg 'invalid_selection')${gl_bai}"; sleep 2 ;;
        esac
    done
}

# ============================================================
# DDoS protection
# ============================================================
enable_ddos() {
    # Rate limit new TCP connections
    iptables -A INPUT -p tcp --syn -m limit --limit 60/s --limit-burst 20 -j ACCEPT
    iptables -A INPUT -p tcp --syn -j DROP
    # Rate limit ICMP
    iptables -A INPUT -p icmp -m limit --limit 10/s -j ACCEPT
    iptables -A INPUT -p icmp -j DROP
    # Drop invalid packets
    iptables -A INPUT -m state --state INVALID -j DROP
    save_iptables_rules
    echo -e "${gl_lv}$(get_fw_msg 'ddos_on')${gl_bai}"
}

disable_ddos() {
    iptables -D INPUT -p tcp --syn -m limit --limit 60/s --limit-burst 20 -j ACCEPT 2>/dev/null
    iptables -D INPUT -p tcp --syn -j DROP 2>/dev/null
    iptables -D INPUT -p icmp -m limit --limit 10/s -j ACCEPT 2>/dev/null
    iptables -D INPUT -p icmp -j DROP 2>/dev/null
    iptables -D INPUT -m state --state INVALID -j DROP 2>/dev/null
    save_iptables_rules
    echo -e "${gl_lv}$(get_fw_msg 'ddos_off')${gl_bai}"
}

# ============================================================
# Country IP blocking via ipset + ipdeny
# ============================================================
manage_country_rules() {
    local action="$1"
    shift
    local country_codes="$@"
    local ipset_name="vps-country"
    ipset list "$ipset_name" &>/dev/null || ipset create "$ipset_name" hash:net 2>/dev/null

    for cc in $country_codes; do
        cc=$(echo "$cc" | tr '[:upper:]' '[:lower:]')
        local tmp_file="/tmp/ipdeny-${cc}.zone"
        wget -q -O "$tmp_file" "https://www.ipdeny.com/ipblocks/data/countries/${cc}.zone" 2>/dev/null
        if [ -f "$tmp_file" ]; then
            while IFS= read -r cidr; do
                [ -z "$cidr" ] && continue
                case "$action" in
                    block)
                        ipset add "$ipset_name" "$cidr" 2>/dev/null
                        iptables -A INPUT -s "$cidr" -j DROP 2>/dev/null
                        ;;
                    allow)
                        iptables -D INPUT -s "$cidr" -j DROP 2>/dev/null
                        ipset del "$ipset_name" "$cidr" 2>/dev/null
                        iptables -I INPUT 1 -s "$cidr" -j ACCEPT 2>/dev/null
                        ;;
                    unblock)
                        iptables -D INPUT -s "$cidr" -j DROP 2>/dev/null
                        iptables -D INPUT -s "$cidr" -j ACCEPT 2>/dev/null
                        ipset del "$ipset_name" "$cidr" 2>/dev/null
                        ;;
                esac
            done < "$tmp_file"
            rm -f "$tmp_file"
        fi
    done
    save_iptables_rules
}

# ============================================================
# Nginx CC Attack Protection
# ============================================================
setup_cc_protection() {
    local action="$1"
    case "$action" in
        on)
            install_pkgs fail2ban
            # Write nginx-cc jail
            cat > /etc/fail2ban/jail.d/nginx-cc.conf << 'EOF'
[nginx-cc]
enabled = true
port = http,https
filter = nginx-cc
logpath = /var/log/nginx/access.log
maxretry = 100
findtime = 60
bantime = 3600
action = iptables-allports[name=nginx-cc]
EOF
            # Write nginx-cc filter
            cat > /etc/fail2ban/filter.d/nginx-cc.conf << 'EOF'
[Definition]
failregex = ^<HOST> -.*"(GET|POST).*HTTP.*" 404 .*$
            ^<HOST> -.*"(GET|POST).*HTTP.*" 403 .*$
            ^<HOST> -.*"(GET|POST).*HTTP.*" 444 .*$
ignoreregex =
EOF
            sys_service restart fail2ban
            echo -e "${gl_lv}$(get_fw_msg 'cc_on')${gl_bai}"
            ;;
        off)
            if [ -f /etc/fail2ban/jail.d/nginx-cc.conf ]; then
                rm -f /etc/fail2ban/jail.d/nginx-cc.conf
                rm -f /etc/fail2ban/filter.d/nginx-cc.conf
                sys_service restart fail2ban
            fi
            echo -e "${gl_lv}$(get_fw_msg 'cc_off')${gl_bai}"
            ;;
    esac
}

# ============================================================
# ModSecurity WAF
# ============================================================
install_modsecurity() {
    local action="$1"
    case "$action" in
        on)
            if command -v nginx &>/dev/null; then
                # Check if nginx has ModSecurity module
                if nginx -V 2>&1 | grep -q 'modsecurity'; then
                    # Enable in nginx conf
                    if [ -d /etc/nginx ]; then
                        mkdir -p /etc/nginx/modsec
                        cat > /etc/nginx/modsec/modsecurity.conf << 'MODSEC'
SecRuleEngine On
SecRequestBodyAccess On
SecResponseBodyAccess On
SecResponseBodyMimeType text/plain text/html text/xml application/json
SecRule REQUEST_HEADERS:Content-Type "text/xml" "id:200000,phase:1,t:none,pass,nolog,ct:text/xml"
SecRule ARGS:test "test" "id:200001,phase:2,t:none,deny,status:403,msg:'Test Attack Detected'"
MODSEC
                        echo -e "${gl_lv}$(get_fw_msg 'waf_on')${gl_bai}"
                        echo -e "${gl_huang}Please add 'modsecurity on;' and 'modsecurity_rules_file /etc/nginx/modsec/modsecurity.conf;' to your nginx sites.${gl_bai}"
                    fi
                else
                    echo -e "${gl_hong}Nginx was not compiled with ModSecurity.${gl_bai}"
                    echo -e "${gl_huang}Install from source with --with-compat --add-dynamic-module=./modsecurity-nginx${gl_bai}"
                fi
            else
                echo -e "${gl_hong}Nginx is not installed. Install web stack first.${gl_bai}"
            fi
            ;;
        off)
            if [ -f /etc/nginx/modsec/modsecurity.conf ]; then
                rm -rf /etc/nginx/modsec
                echo -e "${gl_lv}$(get_fw_msg 'waf_off')${gl_bai}"
            fi
            ;;
    esac
}

# ============================================================
# Port/IP ACL (Blacklist/Whitelist)
# ============================================================
acl_menu() {
    while true; do
        clear
        echo -e "${gl_kjlan}$(get_fw_msg 'acl_title')${gl_bai}"
        echo -e "${gl_lv}1.${gl_bai} $(get_fw_msg 'acl_allow_port')"
        echo -e "${gl_lv}2.${gl_bai} $(get_fw_msg 'acl_block_port')"
        echo -e "${gl_lv}3.${gl_bai} $(get_fw_msg 'acl_allow_ip')"
        echo -e "${gl_lv}4.${gl_bai} $(get_fw_msg 'acl_block_ip')"
        echo -e "${gl_lv}5.${gl_bai} $(get_fw_msg 'acl_list')"
        echo -e "${gl_hong}0.${gl_bai} $(get_msg 'back')"
        read -p "Selection: " acl_ch
        case "$acl_ch" in
            1)
                read -p "$(get_fw_msg 'enter_port'): " acl_port
                iptables -A INPUT -p tcp --dport "$acl_port" -j ACCEPT 2>/dev/null
                iptables -A INPUT -p udp --dport "$acl_port" -j ACCEPT 2>/dev/null
                save_iptables_rules
                echo -e "${gl_lv}Port $acl_port allowed.${gl_bai}"
                break_end
                ;;
            2)
                read -p "$(get_fw_msg 'enter_port'): " acl_port
                iptables -A INPUT -p tcp --dport "$acl_port" -j DROP 2>/dev/null
                iptables -A INPUT -p udp --dport "$acl_port" -j DROP 2>/dev/null
                save_iptables_rules
                echo -e "${gl_hong}Port $acl_port blocked.${gl_bai}"
                break_end
                ;;
            3)
                read -p "Enter IP to allow: " acl_ip
                iptables -A INPUT -s "$acl_ip" -j ACCEPT 2>/dev/null
                save_iptables_rules
                echo -e "${gl_lv}IP $acl_ip allowed.${gl_bai}"
                break_end
                ;;
            4)
                read -p "Enter IP to block: " acl_ip
                iptables -A INPUT -s "$acl_ip" -j DROP 2>/dev/null
                save_iptables_rules
                echo -e "${gl_hong}IP $acl_ip blocked.${gl_bai}"
                break_end
                ;;
            5)
                echo -e "${gl_kjlan}$(get_fw_msg 'fw_list')${gl_bai}"
                iptables -L INPUT -n --line-numbers 2>/dev/null | head -50
                break_end
                ;;
            0) return ;;
            *) echo -e "${gl_hong}$(get_msg 'invalid_selection')${gl_bai}"; sleep 2 ;;
        esac
    done
}

# ============================================================
# Main firewall menu
# ============================================================
firewall_menu() {
    while true; do
        clear
        echo -e "${gl_kjlan}$(get_fw_msg 'title')${gl_bai}"
        echo ""
        echo -e "  ${gl_lv}1.${gl_bai} $(get_fw_msg 'opt_1')"
        echo -e "  ${gl_lv}2.${gl_bai} $(get_fw_msg 'opt_2')"
        echo -e "  ${gl_lv}3.${gl_bai} $(get_fw_msg 'opt_3')"
        echo -e "  ${gl_lv}4.${gl_bai} $(get_fw_msg 'opt_4')"
        echo -e "  ${gl_lv}5.${gl_bai} $(get_fw_msg 'opt_5')"
        echo -e "  ${gl_lv}6.${gl_bai} $(get_fw_msg 'opt_6')"
        echo -e "  ${gl_lv}7.${gl_bai} $(get_fw_msg 'opt_7')"
        echo -e "  ${gl_lv}8.${gl_bai} $(get_fw_msg 'opt_8')"
        echo -e "  ${gl_lv}9.${gl_bai} $(get_fw_msg 'opt_9')"
        echo -e "  ${gl_lv}10.${gl_bai} $(get_fw_msg 'opt_10')"
        echo -e "  ${gl_lv}11.${gl_bai} $(get_fw_msg 'opt_11')"
        echo -e "  ${gl_lv}12.${gl_bai} $(get_fw_msg 'opt_12')"
        echo -e "  ${gl_lv}13.${gl_bai} $(get_fw_msg 'opt_13')"
        echo -e "  ${gl_hong}0.${gl_bai} $(get_msg 'back')"
        read -p "Selection: " choice

        case "$choice" in
            1)
                read -p "$(get_fw_msg 'enter_port'): " fw_port
                if echo "$fw_port" | grep -qE '^[0-9]+$' && [ "$fw_port" -ge 1 ] && [ "$fw_port" -le 65535 ]; then
                    iptables -I INPUT 1 -p tcp --dport "$fw_port" -j ACCEPT 2>/dev/null
                    iptables -I INPUT 1 -p udp --dport "$fw_port" -j ACCEPT 2>/dev/null
                    save_iptables_rules
                    echo -e "${gl_lv}$(get_fw_msg 'open_success')${gl_bai}"
                else
                    echo -e "${gl_hong}$(get_fw_msg 'invalid_port')${gl_bai}"
                fi
                break_end
                ;;
            2)
                read -p "$(get_fw_msg 'enter_port'): " fw_port
                if echo "$fw_port" | grep -qE '^[0-9]+$' && [ "$fw_port" -ge 1 ] && [ "$fw_port" -le 65535 ]; then
                    iptables -D INPUT -p tcp --dport "$fw_port" -j ACCEPT 2>/dev/null
                    iptables -D INPUT -p udp --dport "$fw_port" -j ACCEPT 2>/dev/null
                    save_iptables_rules
                    echo -e "${gl_lv}$(get_fw_msg 'close_success')${gl_bai}"
                else
                    echo -e "${gl_hong}$(get_fw_msg 'invalid_port')${gl_bai}"
                fi
                break_end
                ;;
            3)
                iptables -P INPUT ACCEPT
                iptables -F INPUT
                iptables -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT
                iptables -A INPUT -p tcp --dport 22 -j ACCEPT
                save_iptables_rules
                echo -e "${gl_lv}$(get_fw_msg 'all_open')${gl_bai}"
                break_end
                ;;
            4)
                iptables -P INPUT DROP
                iptables -F INPUT
                iptables -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT
                iptables -A INPUT -p tcp --dport 22 -j ACCEPT
                save_iptables_rules
                echo -e "${gl_hong}$(get_fw_msg 'all_close')${gl_bai}"
                break_end
                ;;
            5) whitelist_menu ;;
            6)
                echo -e "${gl_kjlan}$(get_fw_msg 'fw_list')${gl_bai}"
                iptables -L INPUT -n --line-numbers 2>/dev/null | head -30
                break_end
                ;;
            7)
                echo -e "${gl_kjlan}$(get_fw_msg 'opt_7')${gl_bai}"
                ss -tunap 2>/dev/null | head -30 || netstat -tunap 2>/dev/null | head -30
                break_end
                ;;
            8)
                echo -e "${gl_kjlan}$(get_fw_msg 'opt_8')${gl_bai}"
                get_ip_address
                break_end
                ;;
            9)
                echo -e "${gl_lv}1.${gl_bai} $(get_fw_msg 'ddos_on')"
                echo -e "${gl_lv}2.${gl_bai} $(get_fw_msg 'ddos_off')"
                read -p "Selection: " dd_ch
                case "$dd_ch" in
                    1) enable_ddos ;;
                    2) disable_ddos ;;
                esac
                break_end
                ;;
            10)
                read -p "$(get_fw_msg 'enter_cc'): " country_codes
                echo -e "${gl_lv}1.${gl_bai} Block"
                echo -e "${gl_lv}2.${gl_bai} Allow"
                echo -e "${gl_lv}3.${gl_bai} Unblock"
                read -p "Selection: " cc_ch
                case "$cc_ch" in
                    1) manage_country_rules block $country_codes ;;
                    2) manage_country_rules allow $country_codes ;;
                    3) manage_country_rules unblock $country_codes ;;
                esac
                break_end
                ;;
            11)
                echo -e "${gl_lv}1.${gl_bai} $(get_fw_msg 'cc_on')"
                echo -e "${gl_lv}2.${gl_bai} $(get_fw_msg 'cc_off')"
                read -p "Selection: " cc_ch
                case "$cc_ch" in
                    1) setup_cc_protection on ;;
                    2) setup_cc_protection off ;;
                esac
                break_end
                ;;
            12)
                echo -e "${gl_lv}1.${gl_bai} $(get_fw_msg 'waf_on')"
                echo -e "${gl_lv}2.${gl_bai} $(get_fw_msg 'waf_off')"
                read -p "Selection: " waf_ch
                case "$waf_ch" in
                    1) install_modsecurity on ;;
                    2) install_modsecurity off ;;
                esac
                break_end
                ;;
            13) acl_menu ;;
            0) return ;;
            *) echo -e "${gl_hong}$(get_msg 'invalid_selection')${gl_bai}"; sleep 2 ;;
        esac
    done
}

firewall_menu
